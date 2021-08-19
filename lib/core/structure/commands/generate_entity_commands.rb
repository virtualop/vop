description "each entity gets a command called <entities> automagically"

run do
  result = []

  @op.entities.each do |entity_name, definition|
    $logger.debug "generating entity list command #{definition.list_command_name} (#{definition.plugin.name})"

    plugin = definition.plugin

    list_command = Command.new(plugin, definition.list_command_name)
    list_command.read_only = definition.read_only
    list_command.dont_log = true
    list_command.show_options = definition.show_options

    if definition.on
      list_command.add_param(definition.on.to_s, mandatory: true, entity: true)
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
          if first.is_a? Entity
            entity_array = hash_array
          else
            unless first.is_a? Hash
              raise "entity '#{definition.name}' returned unexpected data type : found #{first.class}, expected Hash"
            end
            entity_array = hash_array.map do |row|
              Entity.new(@op, definition, row)
            end
          end
        end

        # wrap the resulting array of entities to add syntactic sugar
        ::Vop::Entities.new(entity_array)
      end
    end

    list_command.invalidation_block = definition.invalidation_block

    result << list_command
  end

  @op << result

  result
end
