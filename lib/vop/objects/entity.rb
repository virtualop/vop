module Vop

  class Entity

    attr_reader :type, :data, :key

    def initialize(op, definition, data)
      @op = op
      @type = definition.short_name
      @key = definition.key
      @definition = definition
      @data = data

      unless @data.has_key? @key
        raise "key #{key} not found in data : #{data.keys.sort}"
      end

      make_methods_for_commands
      make_methods_for_data
      make_method_for_id
    end

    def id
      @data[@key]
    end

    def [](key)
      @data[key]
    end

    def plugin
      if @data.has_key? "plugin_name"
        @op.plugin(@data["plugin_name"])
      end
    end

    def ancestor_names
      # TODO : would be nice if this operation was transitive
      @op.list_contribution_targets(source_command: @definition.name)
    end

    # all commands that have a parameter with the same name as the entity
    # are considered eligible for this entity (TODO that's too broad, isn't it?)
    def entity_commands
      namified = ancestor_names.map { |x| x.carefully_singularize }
      similar_names = [ @type.to_s ] + namified
      # TODO [performance] this is probably expensive, move into definition time?
      @op.commands.values.flat_map do |command|
        similar_names.map do |similar_name|
          # TODO we might also want to check if param.entity?
          next unless command.params.any? { |param| param.name == similar_name }
          [command.short_name, similar_name]
        end.compact
      end.to_h
    end

    def make_methods_for_commands
      entity_commands.each do |command_name, similar_name|
        # TODO this used to be very similar to code in Vop.<<
        define_singleton_method command_name.to_sym do |*args, &block|
          $logger.debug "[#{@type}:#{id}] #{command_name} (#{args.pretty_inspect}, block? #{block_given?})"
          ruby_args = args.length > 0 ? args[0] : {}
          # TODO we might want to do this only if there's a block param defined
          # TODO this does not work if *args comes with a scalar default param
          if block
            ruby_args["block"] = block
          end
          extra = { similar_name => id }
          if @definition.on
            if @data[@definition.on.to_s]
              extra[@definition.on.to_s] = @data[@definition.on.to_s]
            else
              $logger.warn "entity #{id} does not seem to have data with key #{@definition.on}, though that's required through the 'on' keyword"
            end
          end
          @op.execute(command_name, ruby_args, extra)
        end
      end
    end

    def make_methods_for_data
      @data.each do |k,v|
        define_singleton_method k.to_sym do |*args|
          v
        end
      end
    end

    def make_method_for_id
      define_singleton_method @key.to_sym do |*args|
        id
      end
    end

    def to_json(options = nil)
      {
          entity: type,
          key: key,
          data: data
      }.to_json(options)
    end

    def self.from_json(op, json_data)
      parsed = JSON.parse(json_data)
      entity_name = parsed["entity"]
      definition = op.entities[entity_name]
      new(op, definition, parsed["data"])
    end

    def to_s
      "Vop::Entity (#{@type})"
    end

  end

end
