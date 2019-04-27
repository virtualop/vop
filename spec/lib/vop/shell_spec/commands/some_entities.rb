run do
  thing = OpenStruct.new(short_name: "thing", key: "name")
  [
    Entity.new(@op, thing, {"name" => "foo", "size" => "medium"})
  ]
end
