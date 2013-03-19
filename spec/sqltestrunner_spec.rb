require 'spec_helper'
require 'sqltestrunner'

describe SqlTestRunner do
  let(:sql_connection) { mock('connection', :execute => nil) }
  let(:step_logger) { mock('step_logger', :log_step => nil, :log_before_block => nil) }
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

    describe "before blocks" do
      it "runs a before block outside testcases as well" do
        sql_connection.should_receive(:execute).with("query from before block").ordered
        sql_connection.should_receive(:execute).with("query from stand 0 of testcase name").ordered
        runner.run %Q{
          before do
            execute "query from before block" 
          end
          test_case "name" do
            stand 0 do 
              execute "query from stand 0 of testcase name"
            end
          end
        }
      end
      it "runs more before blocks outside testcases in order of appearence" do
        sql_connection.should_receive(:execute).with("query from before block 1")
        sql_connection.should_receive(:execute).with("query from before block 2").ordered
        sql_connection.should_receive(:execute).with("query from stand 0 of testcase name").ordered
        runner.run %Q{
          before do
            execute "query from before block 1" 
          end
          before do
            execute "query from before block 2" 
          end
          test_case "name" do
            stand 0 do 
              execute "query from stand 0 of testcase name"
            end
          end
        }

      end
    end
  end

  describe "logging " do
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
    it "logs before blocks as well" do
      step_logger.should_receive(:log_before_block).with("first before block").ordered
      step_logger.should_receive(:log_before_block).with("second before block").ordered
      step_logger.should_receive(:log_step).with(0, "name").ordered
      runner.run %Q{ 
        before("first before block") {}
        before("second before block") {}
        test_case("name") { stand 0 } 
      }
    end
  end

  require 'sqlite_connection'
  describe SqliteConnection do
    let(:connection) { SqliteConnection.new(":memory:") }

    it "can execute a query" do
      create_person_table.should be_empty 
    end

    it "can execute a query inserting a row" do
      create_person_table
      expect { insert_person("Gijs", "Heerlen").should == 1 }.to change{person_count}.from([[0]]).to([[1]])
    end

    it "read a single result" do
      create_person_table
      insert_person("Gijs", "Heerlen")
      connection.execute("select * from Person where Id == '1';").should == [[1, "Gijs", "Heerlen"]]
    end

    it "read specific columns" do
      create_person_table
      insert_person("Gijs", "Heerlen")
      connection.execute("select Name, Address from Person where Id == '1';").first.should == ["Gijs", "Heerlen"]
    end

    def create_person_table
      connection.execute(%Q{CREATE TABLE IF NOT EXISTS Person(
                            Id INTEGER PRIMARY KEY,
                            Name VARCHAR(10),
                            Address VARCHAR(30));})
    end

    def insert_person(name, address)
      connection.execute("INSERT INTO Person(Name, Address) VALUES('#{name}', '#{address}');")
      connection.last_insert_id
    end

    def person_count
      connection.execute("SELECT COUNT(*) from Person;")
    end
  end

end
