param "command_name", description: "command for which contributors should be displayed"

run do |plugin, command_name|
  registry = plugin.state[:contributions] || {}
  if command_name
    registry[command_name] || []
  else
    registry
  end
end
