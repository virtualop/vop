def foo
  puts "call for mr. beeblebrox!"
end

require "erb"

def read_template(name)
  path = File.join(@plugin.path, name.to_s + ".erb")
  puts "reading template from #{path}"
  renderer = ERB.new(IO.read(path))
  renderer.result(binding)
end
