description "reloads plugins and commands"

run do
  old = @op
  begin
    @op._reset
  rescue Exception => e
    $stderr.puts("reset failed : #{e.message}")
    @op = old
  end
end
