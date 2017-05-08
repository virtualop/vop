require "vop/plugin"

module Vop

  class PluginLoader

    attr_reader :loaded

    def initialize(vop)
      @op = vop
      @loaded = []
    end

    def new_plugin(plugin_name, plugin_path)
      @plugin = Plugin.new(@op, plugin_name, plugin_path)

      # TODO activate plugin_loader helpers?
      # (this will allow plugins to define helpers that can be used in plugins)
      #@plugin.inject_helpers(self)
      #@plugin.inject_helpers(self, 'plugin_loader')
      @plugin
    end

    def on(hook_sym, &block)
      @plugin.hook(hook_sym, &block)

      core_hooks = %i|before_execute after_execute execute|
      if core_hooks.include? hook_sym
        @op.hook(hook_sym, @plugin.name)
      end
    end

    def dependency(sym)
      @plugin.dependencies << sym.to_s
    end
    alias :depends :dependency

    def autoload(value)
      # TODO make this work on template level?
      @plugin.options[:autoload] = value
    end

    def load(plugins, templates)
      plugins.each do |plugin_path|
        name = File.basename(plugin_path)

        $logger.debug "loading #{name} from #{plugin_path}"
        templates.each do |template|
          template_path = File.dirname(template)
          if plugin_path.start_with? template_path
            $logger.debug "  (applying template #{template_path})"
          end
        end

        plugin_file = File.join(plugin_path, "#{name}.plugin")
        next unless File.exists?(plugin_file)
        $logger.debug "reading plugin '#{name}' from '#{plugin_file}'"

        plugin = new_plugin(name, plugin_path)

        code = File.read(plugin_file)
        begin
          instance_eval(code, plugin_file)
        rescue => detail
          $logger.warn "problem loading plugin #{name} : #{detail.message}\n#{detail.backtrace.join("\n")}"
          raise detail
        end

        @loaded << plugin

        $logger.debug "loaded plugin #{name}"
      end
    end

    def self.read(vop, plugins, templates)
      loader = new(vop)

      loader.load(plugins, templates)

      loader
    end
  end

end
