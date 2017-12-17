module Vop

  class DependencyResolver

    def initialize(op)
      @op = op
    end

    def sort(plugins)
      @plugins = {}
      plugins.each do |plugin|
        @plugins[plugin.name] = plugin
      end

      resolved = []
      unresolved = []

      root_plugin = Plugin.new(@op, "__root__", nil)
      root_plugin.dependencies = @plugins.keys

      $logger.debug "root dummy : #{root_plugin}"

      resolve(root_plugin, resolved, unresolved)
      resolved.delete_if { |x| x == root_plugin.name }

      resolved.map { |x| @plugins[x] }
    end

    def resolve(plugin, resolved, unresolved, level = 0)
      $logger.debug "#{' ' * level}checking dependencies for #{plugin.name}"
      unresolved << plugin.name

      plugin.dependencies.each do |dep|
        $logger.debug "#{' ' * level}resolving #{dep}"
        already_loaded = @op.plugins.map(&:name).include? dep
        unless already_loaded
          unless resolved.include? dep
            if unresolved.include? dep
              raise ::Vop::Errors::RunningInCircles, "circular dependency #{plugin.name} -> #{dep}"
            else
              unless @plugins.has_key? dep
                raise ::Vop::Errors::MissingPlugin, "dependency not met: #{plugin.name} depends on #{dep}"
              end
              dependency = @plugins[dep]
              resolve(dependency, resolved, unresolved, level + 1)
            end
          end
        end
      end

      resolved << plugin.name
    end

  end

end
