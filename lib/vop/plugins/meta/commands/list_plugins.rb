run do
  @op.plugins.map do |name, plugin|
    {
      :name => name,
      :path => plugin.path,
      :loaded => plugin.loaded
    }
  end
end
