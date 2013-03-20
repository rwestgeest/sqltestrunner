require 'sqlite_connection'

module SqlTestRunner
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

    describe "connection error" do
      let(:connection) { SqliteConnection.new('bogus_dir/bogus_connection') }
      it "throws exception" do
        expect { create_person_table }.to raise_exception ConnectionError
      end
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
