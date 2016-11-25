param! 'name'
param! 'plugin', :lookup => lambda { @op.list_plugins.map { |x| x[:name] } }

run do |params|
  pp params
  plugin = @op.list_plugins.select { |x| x[:name] == params['plugin'] }.first

  command_file = File.join(plugin[:path], 'commands', "#{params['name']}.rb")
  File.write(command_file, "run { 42 }")

  @op.reset

  nil
end
