def config(sym)
  @plugin.config[sym]
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

  if name.is_a? Symbol
    # symbols are resolved into entities
    # (only from the moment when list_entities has been loaded, though)
    if @plugin.op.respond_to? :list_entities
      if @plugin.op.list_entities.include? name.to_s
        list_command_name = "list_#{name.to_s.pluralize(42)}"
        p[:lookup] = lambda do |params|
          @plugin.op.send(list_command_name.to_sym).map { |x| x[:name] }
        end
      end
    else
      puts "op not responding to :list_entities (currently resolving param #{name} in #{@command.name})"
    end
  end

  @command.params << p.merge(options)
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
