run do |plugin|
  @op.plugins.map { |x| x.name }.sort
end
