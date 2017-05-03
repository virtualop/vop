module Vop

  # An entity is something that is identifiable through a key, e.g. a name.
  # Also, it groups commands that accept the same parameter: When a command
  # is called on an entity, the parameter with the same name is filled, so
  #   @op.machine("localhost").processes()
  # is equivalent to
  #   @op.processes(machine: "localhost")
  class Entity

    def initialize(op, name, key, hash)
      @op = op
      @name = name
      @key = key
      @data = {}
      hash.each do |k,v|
        @data[k.to_s] = v
      end

      make_methods_for_hash_keys
      make_methods_for_commands
    end

    def inspect
      "Vop::Entity #{@name} (#{@command_count} commands)"
    end

    def make_methods_for_hash_keys
      @data.keys.each do |key|
        next if ['key'].include? key.to_s
        self.class.send(:define_method, key) do |*args|
          ruby_args = args.length > 0 ? args[0] : {}
          @data[key]
        end
      end
    end

    def entity_commands
      result = @op.commands.values.select do |command|
        command.params.select do |param|
          param[:name] == @name
        end.count > 0
      end
      @command_count = result.count
      result
    end

    def make_methods_for_commands
      entity_commands.each do |command|
        value = @data[@key]
        self.class.send(:define_method, command.short_name) do |*args|
          ruby_args = args.length > 0 ? args[0] : {}
          @op.execute(command.short_name, ruby_args, { @name => value })
        end
      end
    end

  end

end
