require 'spec_helper'
require 'sqltestrunner'
describe SqlTestRunner do
  let(:sql_connection) { mock('connection', :execute => nil) }
  let(:step_logger) { mock('step_logger', :log_step => nil) }
  let(:runner) { SqlTestRunner.new(sql_connection, step_logger) }

  describe "test cases" do
    let(:sql_connection) { mock('connection') }

    it "runs a stand block" do
      sql_connection.should_receive(:execute).with("select bla from bla")
      runner.run %Q{
        test_case "name" do
          stand 0 do 
            execute "select bla from bla"
          end
        end
      }
    end

    it "runs stand blocks of different test cases and same key in order" do
      sql_connection.should_receive(:execute).with("first query of stand 0").ordered
      sql_connection.should_receive(:execute).with("second query of stand 0").ordered
      runner.run %Q{
        test_case "name" do
          stand 0 do 
            execute "first query of stand 0"
          end
        end
        test_case "other" do
          stand 0 do 
            execute "second query of stand 0"
          end
        end
      }
    end

    it "runs stand blocks sorted by key" do 
      sql_connection.should_receive(:execute).with("query for stand 0").ordered
      sql_connection.should_receive(:execute).with("query for stand 1").ordered
      runner.run %Q{
        test_case "name" do
          stand 1 do 
            execute "query for stand 1"
          end
          stand 0 do 
            execute "query for stand 0"
          end
        end
      }
    end

    it "runs all sorted by key and then by test case order in file" do 
      sql_connection.should_receive(:execute).with("query for stand 0 of test b").ordered
      sql_connection.should_receive(:execute).with("query for stand 1 of test c").ordered
      sql_connection.should_receive(:execute).with("query for stand 1 of test b").ordered
      runner.run %Q{
        test_case "test c" do
          stand 1 do 
            execute "query for stand 1 of test c"
          end
        end
        test_case "test b" do
          stand 0 do 
            execute "query for stand 0 of test b"
          end
          stand 1 do 
            execute "query for stand 1 of test b"
          end
        end
      }
    end
  end

  describe "logging while running stand blocks" do
    let(:event_logger) { mock('event_logger') }

    it "logs step" do
      step_logger.should_receive(:log_step).with(0, "name")
      runner.run %Q{ test_case("name") { stand 0 } }
    end
    it "logs steps for different test cases" do
      step_logger.should_receive(:log_step).with(0, "name").ordered
      step_logger.should_receive(:log_step).with(0, "other").ordered
      runner.run %Q{ 
        test_case("name") { stand 0 } 
        test_case("other") { stand 0 } 
      }
    end
  end

end
