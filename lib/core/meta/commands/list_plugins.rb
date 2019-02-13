run do |plugin|
  @op.plugins.map(&:name).sort
end
