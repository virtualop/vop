description "initializes a new plugin (folder)"

param! 'name'
param! 'path', :description => 'the path in which to create the new plugin.'

require 'fileutils'

run do |params|
  raise "no such path: #{params['path']}" unless File.exists? params['path']

  # a plugin is a directory
  plugin_path = File.join(params['path'], params['name'])
  Dir.mkdir(plugin_path)

  # with subfolders for commands and helpers
  %w|commands helpers|.each do |thing|
    Dir.mkdir(File.join(plugin_path, thing))
  end

  # and a metadata file called '<name>.plugin'
  plugin_file = params['name'] + '.plugin'
  FileUtils.touch(File.join(plugin_path, plugin_file))

  @op.reset
end
