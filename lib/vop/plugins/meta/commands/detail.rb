param "index", default: 0

run do |shell, index|
  shell.last_table[index.to_i]
end
