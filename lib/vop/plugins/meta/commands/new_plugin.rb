description "initializes a new plugin (folder)"

param! "name"
param! "path", :description => "the path in which to create the new plugin."
param "content"

require "fileutils"

run do |params|
  raise "no such path: #{params["path"]}" unless File.exists? params["path"]

  # a plugin is a directory
  plugin_path = File.join(params["path"], params["name"])
  Dir.mkdir(plugin_path)

  # with subfolders for commands and helpers
  %w|commands helpers|.each do |thing|
    Dir.mkdir(File.join(plugin_path, thing))
  end

  # and a metadata file called "<name>.plugin"
  plugin_file = params["name"] + ".plugin"
  full_name = File.join(plugin_path, plugin_file)
  FileUtils.touch full_name

  # TODO content is [] - should probably be nil, though
  #puts "content: >>#{params["content"].pretty_inspect}<<"
  unless params["content"].nil?
    IO.write(full_name, params["content"])
  end

  $logger.info "created new plugin file #{plugin_file}"

  @op.reset
end
