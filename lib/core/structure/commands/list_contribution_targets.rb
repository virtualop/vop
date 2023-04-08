description "lists the target commands that a given command contributes to (the contributees so to speak)"

param! "source_command"

run do |plugin, source_command|
  registry = plugin.state[:contributions] || {}

  registry.select { |k,v| v.include? source_command.to_s.carefully_pluralize }.keys
end
