module Vop

  module CommandSyntax

    def run(&block)
      @command.block = block
    end

    def description(s)
      @command.description = s
    end

    def resolve_options_string(options)
      if options.is_a? String
        options = {
          description: options
        }
      end
      options
    end

    def param(name, options = {})
      if name.is_a? Symbol
        key = "name" # default for select_machine
        entity = @op.entities.values.select { |x| x.short_name == name.to_s }.first
        if entity.nil?
          raise "entity #{name.to_s} defined as param in #{@command.name} not found"
        else
          key = entity.key
        end

        options[:entity] = true
        options[:lookup] = lambda do
          list_command_name = name.to_s.carefully_pluralize
          the_list = @op.execute(list_command_name, {})
          the_list.map(&key.to_sym)
        end
        name = name.to_s
      end

      options = resolve_options_string(options)

      @command.add_param(name, options)
    end

    def param!(name, options = {})
      options = resolve_options_string(options)
      options.merge! mandatory: true
      param(name, options)
    end

    def read_only
      @command.read_only = true
    end

    def allows_extra
      @command.allows_extra = true
    end

    def show(options = {})
      column_options = options.delete(:columns)
      display_type = options.delete(:display_type)

      raise "unknown keyword #{options.keys.first}" if options.keys.length > 0

      @command.show_options[:columns] = column_options
      @command.show_options[:display_type] = display_type
    end

    def contribute(options, &block)
      @op.register_contributor(
        command_name: options[:to] || @command.short_name,
        contributor: @command.name
      )
      @command.block = block
    end

  end

end
