read_only

run do
  foo()
  config(:identity) || 'localhost'
end
