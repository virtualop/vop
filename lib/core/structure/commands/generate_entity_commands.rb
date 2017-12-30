description "each entity gets a command called <entities> automagically"

run do
  result = []

  @op.entities.each do |entity_name, definition|
    list_command_name = definition.name.carefully_pluralize
    $logger.debug "generating entity list command #{list_command_name} (#{definition.plugin.name})"

    plugin = definition.plugin

    list_command = Command.new(plugin, list_command_name)
    # TODO list_command.read_only = true

    if definition.on
      list_command.add_param(definition.on.to_s, mandatory: true)
    end

    list_command.block = lambda do |params, request, context, plugin|
      ex = Executor.new(@op)
      block_param_names = definition.block.parameters.map { |x| x.last }
      payload = ex.prepare_payload(request, context, block_param_names)

      hash_array = definition.block.call(*payload)
      if hash_array.nil?
        $logger.warn "list block of entity '#{definition.name}' returned nil (?!)"
      else
        unless hash_array.is_a? Array
          raise "unexpected data type : found #{hash_array.class}, expected Array"
        end
        entity_array = []
        unless hash_array.empty?
          first = hash_array.first
          unless first.is_a? Hash
            raise "entity '#{definition.name}' returned unexpected data type : found #{first.class}, expected Hash"
          end
          entity_array = hash_array.map do |row|
            Entity.new(@op, definition.short_name, definition.key, row)
          end
        end

        # wrap the resulting array of entities to add syntactic sugar
        ::Vop::Entities.new(entity_array)
      end
    end
    result << list_command
  end

  @op << result

  result
end
