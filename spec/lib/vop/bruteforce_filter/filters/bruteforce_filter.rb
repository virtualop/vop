run do |command, request, plugin|
  puts "bruteforce filter : #{request.command.name}"
  if request.command.name == "structure.list_plugins"
    raise ::Vop::InterruptChain.new(::Vop::Response.new(42, {}))
  else
    request.next_filter.execute(request)
  end
end
