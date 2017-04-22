description "returns a list of commands with descriptions"

show columns: %i|name short_description|

param 'plugin', :description => 'list of plugins to filter by',
  :multi => true,
  :lookup => lambda { |params| @op.list_plugins.map { |x| x[:name] } },
  :default_param => true

MAX_LENGTH = 80

run do |params|
  @op.commands.select do |name, command|
    not params.has_key?('plugin') or params['plugin'].include?(command.plugin.name)
  end.map do |name, command|
    {
      :name => name,
      :description => command.description || ''
    }.tap do |h|
      h[:short_description] = h[:description][0..MAX_LENGTH]
    end
  end
end
