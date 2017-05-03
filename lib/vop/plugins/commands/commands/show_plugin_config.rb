param! :plugin

run do |params|
  plugin = params['plugin']
  @op.plugins[plugin].config
end
