param! "path"

show display_type: :data

run do |path|
  finder = PluginFinder.new(@op)
  finder.inspect(path)
end
