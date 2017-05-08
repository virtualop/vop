description "reloads plugins and commands"

run do
  old = @op

  worked = false

  begin
    @op._reset
    worked = true
  rescue Exception => e
    $stderr.puts("reset failed : #{e.message}")
    @op = old
  end

  worked
end
