before "creating the person table" do
  execute """
    CREATE TABLE IF NOT EXISTS Person(
      Id INTEGER PRIMARY KEY,
      Name VARCHAR(10),
      Address VARCHAR(30));
  """
end

test_case "1 create a person" do
  stand 0 do
    execute """
      INSERT INTO Person(Name, Address) VALUES('Gijs', 'Heerlen');
    """
    @person_id = last_insert_id
  end

  stand 1 do 
    execute("""
      SELECT Name, Address from Person WHERE Id = #{@person_id}
    """).should == [
      ['Gijs', 'Heerlen']
    ]

  end
end

test_case "silly named person" do
  stand 0 do 
    execute "INSERT INTO Person(Name, Address) VALUES('$%$#%$#', 'Heerlen');"
    execute("SELECT Name FROM Person WHERE Id = '#{last_insert_id}';i").should == [ ['$%$#%$#'] ]
  end
end
