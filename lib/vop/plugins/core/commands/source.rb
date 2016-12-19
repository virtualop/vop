param! "name", :lookup => lambda { @op.list_commands.map { |x| x[:name] } }

run do |params, name|
  @op.command(name).source[:code]
end
