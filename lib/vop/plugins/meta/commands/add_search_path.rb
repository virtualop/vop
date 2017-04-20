description 'adds a new location to the plugin search path (and saves the config)'

param! 'path'

run do |params, plugin|
  @op.add_to_search_path params['path']
  @op.core.write_config
  @op.load_from [ params['path'] ]
end
