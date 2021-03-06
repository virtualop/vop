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

    # all commands that have a parameter with the same name as the entity
    # are considered eligible for this entity (TODO that's too broad, isn't it?)
    def entity_commands
      result = @op.commands.values.select do |command|
        command.params.select do |param|
          param.name == @type
        end.count > 0
      end
      @command_count = result.count
      result
    end

    def make_methods_for_commands
      entity_commands.each do |command|
        # TODO this is very similar to code in Vop.<<
        self.class.send(:define_method, command.short_name) do |*args, &block|
          $logger.debug "[#{@type}:#{id}] #{command.short_name} (#{args.pretty_inspect}, block? #{block_given?})"
          ruby_args = args.length > 0 ? args[0] : {}
          # TODO we might want to do this only if there's a block param defined
          # TODO this does not work if *args comes with a scalar default param
          if block
            ruby_args["block"] = block
          end
          extra = { @type.to_s => id }
          if @definition.on
            if @data[@definition.on.to_s]
              extra[@definition.on.to_s] = @data[@definition.on.to_s]
            else
              $logger.warn "entity #{id} does not seem to have data with key #{@definition.on}, though that's required through the 'on' keyword"
            end
          end
          @op.execute(command.short_name, ruby_args, extra)
        end
      end
    end

    def make_methods_for_data
      @data.each do |k,v|
        self.class.send(:define_method, k) do |*args|
          v
        end
      end
    end

    def make_method_for_id
      self.class.send(:define_method, @key) do |*args|
        id
      end
    end

    def to_json(options = nil)
      {
          entity: @type,
          key: @key,
          data: @data
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
