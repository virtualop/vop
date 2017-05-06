run do
  @op.list_paths.map { |x| x[:path] }
end
