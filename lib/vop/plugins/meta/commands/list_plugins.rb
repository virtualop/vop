run do
  @op.plugins.map do |name, plugin|
    {
      :name => name,
      :path => plugin.path
    }
  end
end
