module Vop

  class DependencyResolver

    def initialize(op, plugins)
      @op = op
      @plugins = plugins      
    end

    def resolve(plugin, resolved, unresolved, level = 0)
      unresolved << plugin.name

      plugin.dependencies.each do |dep|
        unless resolved.include? dep
          if unresolved.include? dep
            raise "running in circles #{plugin.name} -> #{dep}"
          else
            unless @plugins.has_key? dep
              raise "missing dependency: #{plugin.name} depends on #{dep}"
            end
            dependency = @plugins[dep]
            resolve(dependency, resolved, unresolved, level + 1)
          end
        end
      end
      resolved << plugin.name
    end

    def do_it
      resolved = []
      unresolved = []

      root_plugin = Plugin.new(@op, '__root__', nil)
      @plugins.values.each do |plugin|
        root_plugin.dependencies << plugin.name
      end

      resolve(root_plugin, resolved, unresolved)
      resolved.delete_if { |x| x == root_plugin.name }

      resolved.map { |x| @plugins[x] }
    end

    def self.order(op, plugins)
      resolver = DependencyResolver.new(op, plugins)
      resolver.do_it
    end

  end

end
