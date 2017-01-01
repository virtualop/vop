param! :plugin
param! "key"
param! "value"

run do |key, value, params|
  plugin_name = params["plugin"]

  @op.plugins[plugin_name].config ||= {}
  @op.plugins[plugin_name].config[key] = value

  @op.plugins[plugin_name].config
end
