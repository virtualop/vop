description "all read-only commands get <command>! commands that invalidate automagically"

run do
  count = 0
  @op.commands.values.each do |command|
    if command.read_only
      invalidation_command_name = "#{command.short_name}!"
      $logger.debug "generating invalidation command #{invalidation_command_name}"

      invalidation_command = Command.new(command.plugin, invalidation_command_name)
      invalidation_command.params = command.params

      invalidation_command.block = lambda do |params|
        @op.invalidate_cache(
          "command" => command.short_name,
          "raw_params" => params
        )
        @op.execute(command.short_name, params)
      end

      @op << invalidation_command
      count += 1
    end
  end
  count
end
