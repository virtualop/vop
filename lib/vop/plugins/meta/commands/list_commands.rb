description "returns a list of commands with descriptions"

param 'plugin', :description => 'list of plugins to filter by',
  :multi => true,
  :default => [],
  :lookup => lambda { |params| @op.list_plugins.map { |x| x[:name] } },
  :default_param => true

run do |params|
  @op.commands.select do |name, command|
    not params.has_key?('plugin') or params['plugin'].include?(command.plugin.name)
  end.map do |name, command|
    {
      :name => name,
      :description => command.description || ''
    }
  end
end
