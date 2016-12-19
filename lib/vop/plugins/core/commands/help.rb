param! "name", :lookup => lambda { @op.list_commands.map { |x| x[:name] } }

run do |params|
  puts
  puts params["name"]
  command = @op.commands[params["name"]]
  if command.description
    puts "  #{command.description}"
  end

  puts
  puts "syntax:"

  minimal_syntax = command.short_name
  maximal_syntax = command.short_name
  command.params.each do |p|
    example = if p == command.default_param
      "<#{p[:name]}>"
    else
      "#{p[:name]}=<#{p[:name]}>"
    end
    minimal_syntax << " #{example}" if p[:mandatory]
    maximal_syntax << " #{example}"
  end
  puts "  #{minimal_syntax}"
  puts "  #{maximal_syntax}" unless minimal_syntax == maximal_syntax

  if command.params.size > 0
    puts
    puts "parameters:"
    max_param_length = command.params.map { |p| p[:name].length }.max
    command.params.each do |p|
      puts "  %-#{max_param_length}s\t%s" % [p[:name], p[:description]]
    end
  end

  nil
end
