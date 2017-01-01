param! 'name'
param! 'plugin', lookup: lambda { |params| @op.list_plugins.map { |x| x[:name] } }
param 'content', default: nil

run do |params, plugin|
  target_plugin = @op.plugins[params["plugin"]]

  command_name = params['name']

  command_file = File.join(target_plugin.path, "commands", "#{command_name}.rb")
  skeleton = plugin.read_template(:new_command)
  data = params['content'] || skeleton
  File.write(command_file, data)

  $logger.info "wrote command file for #{command_name}"

  @op.reset

  nil
end
