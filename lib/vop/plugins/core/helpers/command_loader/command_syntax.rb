def config(sym)
  @plugin.config[sym]
end

def description(s)
  @command.description = s
end

def param(name, options = {})
  @command.params << {
    :name => name,
    :multi => false,
    :mandatory => false,
    :default_param => false
  }.merge(options)
end

def param!(name, options = {})
  options.merge! :mandatory => true
  param(name, options)
end

def show(options = {})
  column_options = options.delete(:columns)

  raise "unknown keyword #{options.keys.first}" if options.keys.length > 0

  @command.show_options[:columns] = column_options
end
