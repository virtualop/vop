param! "name"

run do |name, plugin|
  registry = plugin.state[:contributions]
  if registry.has_key? name
    registry[name]
  end
end
