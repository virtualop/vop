param! 'name', :lookup => lambda { |params| @op.list_commands.map { |x| x[:name] } }

run do |name|
  @op.command(name).plugin.name
end
