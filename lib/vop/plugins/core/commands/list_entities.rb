run do
  @plugin.state[:entities].map { |x| x[:name] }
end
