param! 'name'

run do |name|
  registry = @op.plugins['core'].state[:contributions]
  if registry.has_key? name
    registry[name]
  end
end
