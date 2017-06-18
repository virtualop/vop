def contribute(options = {}, &block)
  target = options[:to] || @command.short_name

  unless @op.commands.keys.include? target
    # TODO warn about non-existing commands
    #raise "no such command: #{target}"
  end

  @op.plugins["contributions"].state[:contributions][target] << @command.name
  @command.block = block
end
