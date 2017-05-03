param! :command
param! "name"

run do |params, name, plugin|
  command_name = params["command"]

  registry = @op.plugins['contributions'].state[:contributions]
  unless registry.has_key? command_name
    raise "no contributions found for #{command_name}"
  end

  deleted = registry[command_name].delete name
  $logger.info "deleted #{name} from list of contributors to #{command_name} : #{deleted.pretty_inspect}"
end
