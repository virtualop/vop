module Vop

  module EntitySyntax

    def description(s)
      @entity.description = s
    end

    def key(key)
      @entity.key = key
    end

    def entity(options = { key: "name" }, &block)
      run(&block)
    end

    def run(&block)
      @entity.block = block if block
    end

    def on(other_entity)
      @entity.on = other_entity
    end

    def show(options = {})
      column_options = options.delete(:columns)
      display_type = options.delete(:display_type)

      raise "unknown keyword #{options.keys.first}" if options.keys.length > 0

      @entity.show_options[:columns] = column_options if column_options
      @entity.show_options[:display_type] = display_type if display_type
    end

    def invalidate(&block)
      @entity.invalidation_block = block
    end

    def contribute(options, &block)
      raise "missing option 'to'" unless options.has_key?(:to)
      @op.register_contributor(
        command_name: options[:to],
        contributor: @entity.name.to_s.carefully_pluralize
      )
      run(&block)
    end

  end

end
