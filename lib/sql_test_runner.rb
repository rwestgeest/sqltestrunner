require "sql_test_runner/version"

module SqlTestRunner 
  class Runner
    def initialize(sql_connection, step_logger)
      @stands = {}
      @before_blocks = []
      @sql_connection = sql_connection
      @step_logger = step_logger
    end

    def run_file(test_script)
      begin
        run File.read(test_script)
      rescue Errno::ENOENT => e
        raise ScriptNotFound.new(e.message)
      end
    end

    def run(test_description)
      load_tests test_description
      run_stands
      step_logger.log_results
    end

    def load_tests(test_description)
      instance_eval test_description
    end

    def add_stand(stand)
      name = stand.name
      stands[name] = [] unless stands[name]
      stands[name] << stand
    end

    def before(description = "",  &block)
      @before_blocks << BeforeAction.new(self, description, block)
    end

    def test_case(name, &block)
      TestCase.new(self, name).instance_eval(&block)
    end

    private
    def run_stands
      before_blocks.each { |before_block| before_block.run(test_result, sql_connection, step_logger) }
      stands.keys.sort.each do |key|
        stands[key].each do |stand|
          stand.run(test_result, sql_connection, step_logger)
        end
      end
    end
    attr_reader :sql_connection, :step_logger, :stands, :before_blocks, :test_result
  end

  class TestResult
    def initialize(logger)
      @logger = logger
      @errors = []
      @steps_count = 0
    end

    def log_step(step)
      @last_step = step
      @steps_count += 1
      logger.log_step(step)
    end

    def log_error(error)
      error = ExpectationNotMetError.new(error, @last_step)
      logger.log_error(error)
      @errors << error
    end

    def error_count
      @errors.size
    end

    def log_results
      logger.log_results(self)
    end

    def summary
      lines = errors.map { |error| error.summary }
      lines << "#{@steps_count} testcases - #{error_count} failures"
      lines.join $/
    end

    attr_reader :logger, :errors
  end

  class TestCase < Struct.new(:runner, :name)
    def stand(stand_name, &block)
      runner.add_stand(Stand.new(self, stand_name, block))
    end
    def to_s
      name
    end
    def description
      "testcase #{name}"
    end
  end

  class Step < Struct.new(:parent, :name, :block)
    def run(test_result, sql_connection, step_logger)
      step_logger.log_step(self)
      begin
        sql_connection.instance_eval(&block) if block
      rescue RSpec::Expectations::ExpectationNotMetError => e
        step_logger.log_error(e)
      end
    end
  end

  class Stand < Step
    def description
      "#{parent.description} - stand #{name}"
    end
  end

  class BeforeAction < Step
    def description
      "before: #{name}"
    end
  end

  class ExpectationNotMetError < Struct.new(:error, :caused_by_step)
    def summary
      "In #{caused_by_step.description}: #{error.message}"
    end
  end

  class ScriptNotFound < Exception
  end

  class ReportingStepLogger 
    def initialize(output = $stdout)
      @output = output
    end
    def log_step(step)
      @output.puts step.description
    end
    def log_error(error)
      @output.puts error.summary
    end
    def log_results(results)
      @output.puts "--- Done -- "
      @output.puts "Summary:"
      @output.puts results.summary
    end
  end
end
