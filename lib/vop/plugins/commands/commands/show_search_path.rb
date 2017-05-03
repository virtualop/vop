param 'core', default: false

run do |params, core|
  if core
    @op.core_path
  else
    @op.search_path
  end
end
