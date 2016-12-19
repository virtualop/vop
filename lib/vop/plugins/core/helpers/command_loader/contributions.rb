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

def with_contributions(options = {}, &block)
  raise "untested"
  collected = @op.collect_contributions('name' => command_name, 'raw_params' => params)
  params_with_contributions = params.merge(:contributions => collected)
  list = block.call(params_with_contributions)

  found = list.select { |x| x[key.to_sym] == params[key] }
  if found && found.size > 0
    Entity.new(@op, command_name, key, found.first)
  else
    raise "no such entity : #{params[key]} [#{command_name}]"
  end
end
