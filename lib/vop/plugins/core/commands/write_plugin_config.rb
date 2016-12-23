param! 'plugin'

run do |params|
  plugin_name = params['plugin']
  plugin = @op.plugins[plugin_name]
  plugin.write_config
end
