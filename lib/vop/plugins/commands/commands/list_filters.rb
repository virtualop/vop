description "returns a list of filters with descriptions"

param 'plugin', :description => 'list of plugins to filter by',
  :multi => true,
  :lookup => lambda { |params| @op.list_plugins.map { |x| x[:name] } },
  :default_param => true

run do |params|
  @op.filters.select do |name, filter|
    not params.has_key?('plugin') or params['plugin'].include?(filter.plugin.name)
  end.map do |name, filter|
    {
      :name => name,
      :description => filter.description || ''
    }
  end
end
