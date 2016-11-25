param! "command"

run do |command|
  system(command, out: $stdout, err: :out)
end
