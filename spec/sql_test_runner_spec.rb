require 'spec_helper'
require 'sql_test_runner'

module SqlTestRunner
  describe Runner do
    let(:sql_connection) { mock('connection', :execute => nil) }
    let(:step_logger) { mock('step_logger').as_null_object }
    let(:result) { TestResult.new(step_logger) }
    let(:runner) { Runner.new(sql_connection,result) }

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
      class SimpleLoggerToString < Struct.new(:log)
        def log_step(step)
          log << "#{step.description}"
        end

        def log_results(results)
          log << results.summary
        end
      end

      let(:step_logger) { SimpleLoggerToString.new(logged_strings) }
      let(:logged_strings) { [] }

      it "logs step" do
        runner.run %Q{ test_case("name") { stand 0 } }
        logged_strings.should include "testcase name - stand 0"
      end

      it "logs steps for different test cases" do
        runner.run %Q{ 
          test_case("name") { stand 0 } 
          test_case("other") { stand 0 } 
        }
        logged_strings[0,2].should == [
          "testcase name - stand 0",
          "testcase other - stand 0"
        ]
      end

      it "logs before blocks as well" do
        runner.run %Q{ 
          before("first") {}
          before("second") {}
          test_case("name") { stand 0 } 
        }
        logged_strings[0,3].should == [
          "before: first",
          "before: second",
          "testcase name - stand 0"
        ]
      end

      it "logs results" do
        runner.run %Q{} 
        logged_strings.should == ["0 testcases - 0 failures"]
      end
    end

    describe "running a file" do
      let(:script_name) { File.expand_path('example_script.sql', File.dirname(__FILE__)) }
      before { create_file(script_name, 'before { execute "query" }') }
      after { delete_file(script_name) }

      it "runs the script" do
        sql_connection.should_receive(:execute).with("query")
        runner.run_file(script_name)
      end

      def create_file(filename, content)
        delete_file(filename)
        File.open(filename, "w+") { |file| file.write(content) }
      end

      def delete_file(filename)
        File.delete(filename) if File.exists?(filename)
      end
    end

    describe "expectations" do
      let(:rspec_expectation_error) { create_expectation_error }
      it "can compare stuff" do
        runner.run %Q{ test_case("name") { stand(0) { 2.should == 2 } } }
      end

      it "failing compare does not raise exception" do
        expect {
          runner.run %Q{ test_case("name") { stand(0) { 2.should == 4 } } }
        }.not_to raise_exception
      end

      it "failing compare adds error to list of errors" do
        expect { runner.run %Q{ test_case("name") { stand(0) { 2.should == 4 } } } }.to change {result.error_count}.by(1)
        result.errors.last.summary.should == "In testcase name - stand 0: #{rspec_expectation_error.message}"
      end

      it "failing before adds error to list of errors" do
        expect { runner.run %Q{ before("description") { 2.should == 4 } } }.to change {result.error_count}.by(1)
        result.errors.last.summary.should == "In before: description: #{rspec_expectation_error.message}"
      end

      def create_expectation_error 
        begin 
          2.should == 4
        rescue Exception => e
          return e
        end
      end

    end

  end

  describe TestResult do
    let(:step_logger) { mock('step_logger').as_null_object }
    let(:result) { TestResult.new(step_logger) }
    let(:step) { BeforeAction.new(nil, "name") }
    let(:rspec_expectation_error) { create_expectation_error }
    def create_expectation_error 
      begin 
        2.should == 4
      rescue Exception => e
        return e
      end
    end

    describe "logging step" do

      it "logs the step to the logger" do
        step_logger.should_receive(:log_step).with step
        result.log_step(step)
      end
      describe "and an error" do
        it "logs the error tot the logger" do
          step_logger.should_receive(:log_step).with step
          step_logger.should_receive(:log_error) do |error|
            error.summary.should == "In before: name: #{rspec_expectation_error.message}"
          end
          result.log_step(step)
          result.log_error(rspec_expectation_error)
        end
      end
    end

    describe "logging results" do
      it "logs itself" do
        step_logger.should_receive(:log_results).with result
        result.log_results
      end
    end

    describe "summary" do
      subject { result.summary }
      it { should == "0 testcases - 0 failures" }

      describe "when steps logged" do
        before { result.log_step(step) }
        it { should == "1 testcases - 0 failures" }

        describe "and errors logged" do
          before { result.log_error(rspec_expectation_error) }
          it { should include "1 testcases - 1 failures" }
          it { should include rspec_expectation_error.message }
        end

      end
    end
  end

  describe ReportingStepLogger do
    let(:output)  { StringIO.new }
    let(:step_logger) { ReportingStepLogger.new(output) }
    describe "logging step" do
      it "logs the step to the output" do
        step_logger.log_step(stub('step', :description => "message"))
        output.string.should include "message"
      end
    end
    describe "logging error" do
      it "logs the error's summary to output" do
        step_logger.log_error(stub('error', :summary => "message"))
        output.string.should include "message"
      end
    end
    describe "logging results" do
      it "logs the results summary to output" do
        step_logger.log_results(stub('results', :summary => "message"))
        output.string.should include "message"
      end
    end
  end


end
