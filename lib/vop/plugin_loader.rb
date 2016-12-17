require 'vop/plugin'
require 'pp'

module Vop

  class PluginLoader

    attr_reader :op
    attr_reader :dir

    def initialize(op, dir)
      @op = op
      @dir = dir
    end

    def new_plugin(plugin_name, plugin_path)
      @plugin = Plugin.new(@op, plugin_name, plugin_path)

      # TODO activate plugin_loader helpers?
      # (this will allow plugins to define helpers that can be used in plugins)
      #@plugin.inject_helpers(self)
      #@plugin.inject_helpers(self, 'plugin_loader')

      @op.plugins[plugin_name] = @plugin
      @plugin
    end

    def on(hook_sym, &block)
      @plugin.hook(hook_sym, &block)
    end

    def dependency(sym)
      @plugin.dependencies << sym.to_s
    end
    alias_method :depends, :dependency

    def read_plugin_template
      template_path = File.join(@dir, 'plugin.vop')
      plugin_template = nil
      if File.exists?(template_path)
        plugin_template = IO.read(template_path)
      end
      if plugin_template
        begin
          self.instance_eval plugin_template
        rescue => e
          $stderr.puts "could not load plugin #{template_path} : " + e.message
          $stderr.puts e.backtrace.join("\n")
          raise e
        end
      end
    end

    def self.read(op, dir)
      $logger.debug("scanning dir #{dir} for plugins...")

      loader = new(op, dir)
      loader.read_plugin_template

      Dir.new(dir).each do |plugin_name|
        next if /^\./.match(plugin_name)

        plugin_path = File.join(dir, plugin_name)
        file_name = File.join(plugin_path, "#{plugin_name}.plugin")
        next unless File.exists?(file_name)
        $logger.debug("reading plugin '#{plugin_name}' from '#{file_name}'")

        plugin = loader.new_plugin(plugin_name, plugin_path)

        code = File.read(file_name)
        begin
          loader.instance_eval(code, file_name)
        rescue => detail
          raise "problem loading plugin #{plugin_name} : #{detail.message}\n#{detail.backtrace.join("\n")}"
        end

        $logger.debug "loaded plugin #{plugin_name}"
      end
    end

  end

end
