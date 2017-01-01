param! "dir"

run do |dir|
  finder = PluginFinder.new(@op)
  (plugins, _templates) = finder.scan(dir)
  plugins
end
