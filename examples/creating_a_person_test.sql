before "creating the person table" do
  execute %Q{
    CREATE TABLE IF NOT EXISTS Person(
      Id INTEGER PRIMARY KEY,
      Name VARCHAR(10),
      Address VARCHAR(30));
  }
end

test_case "create a person" do
  stand 0 do
    execute %Q{
      INSERT INTO Person(Name, Address) VALUES('Gijs', 'Heerlen');
    }
    @person_id = last_insert_id
  end

  stand 1 do 
    execute( %Q{
      SELECT * from Person WHERE Id = #{@person_id}
    }).should == [
      [1, 'Gijs', 'Heerlen']
    ]

  end
end

test_case "silly named person" do
  stand 0 do 
    execute %Q{INSERT INTO Person(Name, Address) VALUES('$%$#%$#', 'Heerlen');}
    execute(%Q{SELECT Name FROM Person WHERE Id = '#{last_insert_id}';}).should == [ ['$%$#%$#'] ]
  end
end
