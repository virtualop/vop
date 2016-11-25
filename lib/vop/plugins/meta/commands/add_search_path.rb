param! 'path'

run do |params|
  @op.config[:search_path] << params['path']
  @op.reset
end
