description "writes an empty search path into the config - so it will start again with only the core plugins enabled"

run do
  @op.core.config[:search_path] = []
  @op.core.write_config
  @op.reset
end
