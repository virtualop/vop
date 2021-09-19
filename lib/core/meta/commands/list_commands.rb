param "plugin_filter", description: "name of a plugin by which commands should be filtered",
  lookup: lambda { @op.list_plugins }

run do |plugin_filter|
  result = @op.commands.values

  unless plugin_filter.nil?
    result.delete_if { |command| command.plugin.name != plugin_filter }
  end

  result.map { |command| command.name }.sort
end
