description "reloads plugins and commands"

param "fail_hard", :default => false

run do |fail_hard|
  old = @op

  worked = false
  fail_message = ""

  begin
    @op._reset
    worked = true
  rescue Exception => e
    fail_message = e.message
    $stderr.puts("reset failed : #{fail_message}")
    @op = old
  end

  if fail_hard && ! worked
    raise ::Vop::SyntaxError, "reset failed: #{fail_message}"
  end

  worked
end
