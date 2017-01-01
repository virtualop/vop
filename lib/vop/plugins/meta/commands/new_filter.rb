param! 'name'
param! 'plugin', :lookup => lambda { |params| @op.list_plugins.map { |x| x[:name] } }
param 'content', :default => nil

run do |params, plugin|
  puts "plugin : #{plugin.name}"
  target_plugin = @op.plugins[params["plugin"]]

  filter_name = params['name']

  filters_path = File.join(target_plugin.path, "filters")
  FileUtils.mkdir_p filters_path
  file_name = File.join(filters_path, "#{filter_name}.rb")
  skeleton = plugin.read_template(:new_filter)
  data = params["content"] || skeleton
  File.write(file_name, data)

  $logger.info "wrote filter file for #{filter_name}"
  $logger.debug data

  @op.reset

  nil
end
