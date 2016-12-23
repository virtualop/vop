# TODO remove?
def accept_contributions
  #puts "#{@command.name} accepts contributions"
  # TODO this init should happen earlier
  #@op.plugins['core'].state[:contributions] ||= Hash.new { |h,k| h[k] = [] }
end

def contribute(options = {}, &block)
  target = options[:to] || @command.short_name
  #puts "#{@command.name} contributes to #{target}"
  # TODO check that the command exists
  @op.plugins['core'].state[:contributions][target] << @command.name
  @command.block = block
end
