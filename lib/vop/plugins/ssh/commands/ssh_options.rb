param! 'machine'

show :display_type => :hash

run do |params|
  @op.collect_contributions(
    "name" => 'ssh_options',
    "raw_params" => params
  )
end
