module Vop

  module EntitySyntax

    def description(s)
      @entity.description = s
    end

    def key(key)
      @entity.key = key
    end

    def entity(options = { key: "name" }, &block)
      if block
        run(&block)
      end
    end

    def run(&block)
      @entity.block = block
    end

    def on(other_entity)
      @entity.on = other_entity
    end

    def show(options = {})
      column_options = options.delete(:columns)
      display_type = options.delete(:display_type)

      raise "unknown keyword #{options.keys.first}" if options.keys.length > 0

      @entity.show_options[:columns] = column_options
      @entity.show_options[:display_type] = display_type
    end

    def invalidate(&block)
      @entity.invalidation_block = block
    end

  end

end
