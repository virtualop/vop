def config(sym)
  @plugin.config ?
    @plugin.config[sym] :
    nil
end

def description(s)
  @command.description = s
end

def param(name, options = {})
  p = {
    :name => name.to_s,
    :multi => false,
    :mandatory => false,
    :default_param => false
  }

  # parameters whose names are symbols are resolved into entities
  if name.is_a? Symbol
    op = @plugin.op

    entity_names = op.plugins['commands'].state[:entities].map { |entity| entity[:name] }
    if entity_names.include? name.to_s
      list_command_name = "list_#{name.to_s.pluralize(42)}"
      p[:lookup] = lambda do |params|
        # TODO :name is probably specific to the entity (key?)
        op.send(list_command_name.to_sym).map { |x| x[:name] }
      end
    end
  end

  # auto-detect boolean parameters
  if options.has_key? :default
    if options[:default] == true || options[:default] == false
      options[:boolean] = true
    end
  end

  @command.params << p.merge(options)
end

def param!(name, options = {})
  options.merge! :mandatory => true
  param(name, options)
end

def read_only
  @command.read_only = true
end

def show(options = {})
  column_options = options.delete(:columns)
  display_type = options.delete(:display_type)

  raise "unknown keyword #{options.keys.first}" if options.keys.length > 0

  @command.show_options[:columns] = column_options
  @command.show_options[:display_type] = display_type
end
