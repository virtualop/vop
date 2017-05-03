param! :command
param! :block

run do |command, block|
  target = options[:to] || @command.short_name
  #puts "#{@command.name} contributes to #{target}"
  # TODO check that the command exists
  @op.plugins['core'].state[:contributions][target] << @command.name
  @command.block = block
end
