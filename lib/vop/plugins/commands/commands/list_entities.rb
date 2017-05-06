run do |plugin|
  plugin.state[:entities].map { |x| x[:name] }
end
