param! 'name'
param! 'plugin', :lookup => lambda { @op.list_plugins.map { |x| x[:name] } }
param 'content'

run do |params, plugin, content|
  target_plugin = @op.plugins[params["plugin"]]
  puts "target_plugin : #{target_plugin}"

  command_file = File.join(target_plugin.path, 'commands', "#{params['name']}.rb")
  skeleton = plugin.read_template(:new_command)
  data = content || skeleton
  File.write(command_file, data)

  @op.reset

  nil
end
