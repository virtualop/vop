description "all read-only commands get <command>! commands that invalidate automagically"

run do
  count = 0

  def setup_invalidation_command(thing, invalidation_command_name, command_name)
    if thing.read_only || thing.invalidation_block
      $logger.debug "generating invalidation command #{invalidation_command_name}"

      invalidation_command = Command.new(thing.plugin, invalidation_command_name)
      invalidation_command.params = thing.params

      invalidation_command.block = lambda do |params|
        @op.invalidate_cache(
          "command" => command_name,
          "raw_params" => params
        )
        @op.execute(command_name, params)
      end

      @op << invalidation_command
    end
  end

  @op.commands.values.each do |command|
    setup_invalidation_command(command, "#{command.short_name}!", command.short_name)
    count += 1
  end

  # not needed at the moment (because entity list commands are generated with an invalidation block)
  # @op.entities.values.each do |entity|
  #   setup_invalidation_command(entity, "#{entity.list_command_name}!", entity.list_command_name)
  #   count += 1
  # end

  count
end
