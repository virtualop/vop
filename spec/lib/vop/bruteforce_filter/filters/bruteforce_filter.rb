run do |command, request, plugin|
  raise ::Vop::InterruptChain.new(::Vop::Response.new(42, {}))
end
