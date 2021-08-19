param! "name",
  description: "a command for which help should be displayed",
  lookup: lambda { |params| @op.list_commands }

run do |params, name|
  command = @op.commands[params["name"]]
  if command.nil?
    raise "no such command : #{name}"
  end

  puts
  puts command.name

  if command.description
    puts "  #{command.description}"
  end

  puts
  puts "syntax:"

  minimal_syntax = command.short_name
  maximal_syntax = command.short_name
  command.params.each do |p|
    example = if p == command.default_param
      "<#{p.name}>"
    else
      "#{p.name}=<#{p.name}>"
    end
    minimal_syntax << " #{example}" if p.options[:mandatory]
    maximal_syntax << " #{example}"
  end
  puts "  #{minimal_syntax}"
  puts "  #{maximal_syntax}" unless minimal_syntax == maximal_syntax

  if command.params.size > 0
    puts
    puts "parameters:"
    max_param_length = command.params.map { |p| p.name.length }.max
    command.params.each do |p|
      default_text = ""
      if p.options.key? :default
        default_text += " (default: #{p.options[:default]})"
      end
      puts "  %-#{max_param_length}s\t%s\t%s" % [p.name, p.options[:description], default_text]
    end
  end

  nil
end
