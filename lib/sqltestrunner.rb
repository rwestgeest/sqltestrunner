require "sqltestrunner/version"

class SqlTestRunner
  def initialize(sql_test_runner, step_logger = nil)
    @stands = {}
    @sql_test_runner = sql_test_runner
    @step_logger = step_logger
  end

  def run test_description
    load_tests test_description
    run_stands
  end

  def load_tests(test_description)
    instance_eval test_description
  end

  def add_stand(number, stand)
    stands[number] = [] unless stands[number]
    stands[number] << stand
  end

  def test_case(name, &block)
    TestCase.new(self,name).instance_eval(&block)
  end

  class TestCase < Struct.new(:runner, :name)
    def stand(number, &block)
      runner.add_stand(number, Stand.new(name, number, block))
    end
  end

  class Stand < Struct.new(:name, :key, :block)
    def run(sql_test_runner, step_logger)
      step_logger.log_step(key, name)
      sql_test_runner.instance_eval(&block) if block
    end
  end

  private
  def run_stands
    stands.keys.sort.each do |key|
      stands[key].each do |stand|
        stand.run(sql_test_runner, step_logger)
      end
    end
  end
  attr_reader :sql_test_runner, :step_logger, :stands
end

class ReportingStepLogger 
  def log_step(step, test_case)
    puts "running stand #{step} for #{test_case}"
  end
end
