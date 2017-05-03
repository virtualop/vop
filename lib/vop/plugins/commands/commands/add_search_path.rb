description "adds a new location to the plugin search path (and saves the config)"

param! "path"

run do |params, plugin|
  core = @op.core

  core.config ||= {}
  core.config["search_path"] ||= []
  core.config["search_path"] << params["path"]

  core.write_config
  @op.load_from [ params["path"] ]
end
