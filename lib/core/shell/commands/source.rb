param! "name", lookup: lambda { @op.commands.keys + @op.entities.keys + @op.filters.keys }
param "numbers", default: true

run do |name, numbers|
  (source, thing) = if @op.commands.keys.include? name
    [ :commands, @op.commands[name] ]
  elsif @op.entities.keys.include? name
    [ :entities, @op.entities[name] ]
  elsif @op.filters.keys.include? name
    [ :filters, @op.filters[name] ]
  end

  code = thing.source[:code]

  result = []
  result << " "
  code.lines.each_with_index { |line, idx|
    line.chomp!
    line = numbers ?
      "%02d %s" % [idx+1, line] :
      line

    result << line
  }
  result << " "
  result.join("\n")
end
