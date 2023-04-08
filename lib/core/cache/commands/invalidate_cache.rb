param! "command"
param! "raw_params", default: {}

run do |params|
  @op.collect_contributions(
    command_name: "invalidate_cache",
    raw_params: params
  )
end
