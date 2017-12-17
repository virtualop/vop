require_relative "../objects/plugin"
require_relative "../syntax/plugin_syntax"
require_relative "../util/errors"

module Vop

  class PluginLoader

    attr_reader :loaded

    def initialize(op)
      @op = op

      extend PluginSyntax
    end

    def reset
      @loaded = []
    end

    def new_plugin(plugin_name, plugin_path, plugin_options = {})
      @plugin = Plugin.new(@op, plugin_name, plugin_path, plugin_options)
      @plugin
    end

    def read_plugin(code, source_file = nil)
      begin
        instance_eval(code, source_file)
      rescue => detail
        $logger.warn "problem loading plugin #{@plugin.name} : #{detail.message}\n#{detail.backtrace.join("\n")}"
        raise Errors::PluginLoadError.new(detail)
      end
    end

    def load(found, plugin_options = {})
      reset

      (plugins, templates) = [found.plugins, found.templates]

      plugins.each do |plugin_path|
        name = File.basename(plugin_path)

        $logger.debug "loading #{name} from #{plugin_path}"
        plugin = new_plugin(name, plugin_path, plugin_options)

        templates.each do |template|
          template_path = File.dirname(template)
          if plugin_path.start_with? template_path
            $logger.debug "  (applying template #{template_path})"
            template_file = File.join(template_path, "plugin.vop")
            code = File.read(template_file)
            read_plugin(code, template_file)
          end
        end

        plugin_file = File.join(plugin_path, "#{name}.plugin")
        next unless File.exists?(plugin_file)
        $logger.debug "reading plugin '#{name}' from '#{plugin_file}'"

        code = File.read(plugin_file)
        read_plugin(code, plugin_file)
        @loaded << @plugin

        $logger.debug "loaded plugin #{@plugin.name}"
      end

      self
    end

  end

end
