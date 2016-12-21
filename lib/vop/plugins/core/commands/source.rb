param! "name", :lookup => lambda { |_| @op.list_commands.map { |x| x[:name] } }

run do |params, name|
  @op.command(name).source[:code]
end
