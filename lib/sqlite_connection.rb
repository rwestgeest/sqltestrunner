require 'sqlite3'
require 'rspec/expectations'

module SqlTestRunner
  class ConnectionError < Exception

  end

  class SqliteConnection < Struct.new(:connection_string)
    RSpec::Expectations::Syntax.enable_should(self)

    def execute(query)
      connection.execute(query)
    end

    def last_insert_id
      connection.last_insert_row_id
    end

    private
    def connection 
      @connection ||= create_connection
    end
    def create_connection
      begin
      SQLite3::Database.open(connection_string)
      rescue Exception => e
        raise ConnectionError.new(e.message)
      end
    end
  end

end
