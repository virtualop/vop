run do
  @op.plugins.map do |name, plugin|
    {
      :name => name,
      :path => Pathname.new(plugin.path).realpath,
      :loaded => plugin.loaded
    }
  end
end
