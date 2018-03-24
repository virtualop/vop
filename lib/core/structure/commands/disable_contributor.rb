param! "command_name", "command for which a contributor should be disabled"
param! "contributor", "name of the contributor to disable"

run do |plugin, command_name, contributor|
  registry = plugin.state[:contributions] || {}
  unless registry.has_key? command_name
    raise "no contributors found for command #{command_name}"
  end

  contributors = registry[command_name]
  unless contributors.include? contributor
    raise "no contributor found with name #{contributor} for command #{command_name}"
  end

  contributors.delete(contributor)
end
