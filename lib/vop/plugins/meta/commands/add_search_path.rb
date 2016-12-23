param! 'path'

run do |params, plugin|
  @op.add_to_search_path(params['path'])
  @op.write_plugin_config 'core'
  @op.reset
end
