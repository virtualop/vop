require 'fileutils'

param! 'name'

run do |params|
  name = params['name']

  plugin = @op.plugins[name]
  raise "no such plugin : #{name}" unless plugin

  FileUtils.rm_r plugin.path
  @op.reset
end
