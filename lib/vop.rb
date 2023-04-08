require "pathname"

require_relative "vop/version"
require_relative "vop/shell/shell"
require_relative "vop/vop"

begin
  require "vop-plugins"
rescue Exception => e
  $stderr.puts "could not load plugins : #{e.message}"
  #raise
end

module Vop

  def self.setup(options = {})
    ::Vop::Vop.new(options)
  end

  def self.boot(options = {})
    if ENV["VOP_DEV_MODE"]
      sibling_lib_dir = Pathname.new(File.join(File.dirname(__FILE__), "..", "lib")).realpath
      if File.exists? sibling_lib_dir
        $: << sibling_lib_dir
      end
    end

    if ENV["VOP_ORIGIN"]
      options[:origin] = "#{ENV["VOP_ORIGIN"]}:#{Process.pid}@#{`hostname`.strip}"
    end

    ::Vop.setup(options)
  end

  def vop_setup(options = {})
    ::Vop.boot(options)
  end

end
