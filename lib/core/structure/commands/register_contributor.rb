param! "command_name", description: "the target of the contribution"
param! "contributor", description: "the command that contributes"

run do |command_name, contributor, plugin|
  # TODO verify that +command+ exists - cannot do it here because of
  # 'machines.rails_machines' tries to contribute to unknown command 'machine'
  # unless @op.commands.keys.include? command
  #   raise "'#{contributor}' tries to contribute to unknown command '#{command}'"
  # end

  # TODO initialize in init_hook (not here and in list_contributors)
  registry = plugin.state[:contributions] ||= Hash.new { |h,k| h[k] = [] }
  registry[command_name] << contributor
end
