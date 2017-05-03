def contribute(options = {}, &block)
  target = options[:to] || @command.short_name

  @op.plugins['contributions'].state[:contributions][target] << @command.name
  @command.block = block
end
