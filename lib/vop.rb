require 'pp'
require 'logger'
require 'pathname'

require 'vop/plugin_loader'

module Vop

  VOP_ROOT = Pathname.new(File.join(File.dirname(__FILE__), '..')).realpath
  CORE_PLUGIN_PATH = Pathname.new(File.join(File.dirname(__FILE__), 'vop', 'plugins')).realpath
  #CONFIG_PATH = '/etc/vop'
  #PLUGIN_CONFIG_PATH = File.join(CONFIG_PATH, 'plugins.d')

  class Vop

    DEFAULTS = {
      :search_path => [
        File.join(VOP_ROOT, '..', 'plugins/standard'),
        File.join(VOP_ROOT, '..', 'plugins/extended')
      ],
      :command_dir_name => 'commands',
      :plugin_config => {

      }
    }

    attr_reader :config

    attr_reader :plugins
    attr_reader :commands

    def initialize(options = {})
      at_exit {
        self.shutdown
      }

      @version = '0.3.0'

      @config = DEFAULTS
      @config.merge! options

      $logger = Logger.new(STDOUT)
      $logger.level = options['--verbose'] ? Logger::DEBUG : Logger::INFO

      _reset

      $logger.info "virtualop (#{@version}) init complete."
      $logger.info "hello."
    end

    def inspect
      chunk_size = 25
      plugin_string = @plugins.keys.sort[0..chunk_size-1].join(' ')
      if @plugins.length > chunk_size
        plugin_string += " + #{@plugins.length - chunk_size} more"
      end
      "vop #{@version} (#{plugin_string})"
    end

    def _reset
      $logger.debug "loading..."

      load_plugins
      make_methods

      $logger.info "loaded #{@commands.size} commands from #{@plugins.size} plugins"
    end

    def _search_path
      [ CORE_PLUGIN_PATH ] + config[:search_path]
    end

    def load_plugins
      @plugins = {}
      @commands = {}

      # step 1 : read plugins from all existing source dirs
      candidates = _search_path
      search_path = candidates.select { |path| File.exists? path }
      search_path.each do |path|
        PluginLoader.read(self, path)
      end

      # step 2 : activate plugins (in the right order)
      ordered_plugins.each do |plugin|
        plugin.init
      end
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

    def ordered_plugins
      root_plugin = Plugin.new(self, '__root__', nil)
      @plugins.values.each do |plugin|
        root_plugin.dependencies << plugin.name
      end
      resolved = []
      unresolved = []

      resolve(root_plugin, resolved, unresolved)
      resolved.delete_if { |x| x == root_plugin.name }

      resolved.map { |x| @plugins[x] }
    end

    def command(name)
      unless commands.has_key?(name)
        raise "no such command : #{name}"
      end

      commands[name]
    end

    def make_methods
      @commands.each do |name, command|
        self.class.send(:define_method, name) do |*args|
          ruby_args = args.length > 0 ? args[0] : {}
          self.execute(name, ruby_args)
        end
      end
    end

    def execute(command_name, param_values, extra = {})
      result = execute_command(command_name, param_values, extra)
      result[:data]
    end

    def execute_command(command_name, param_values, extra = {})
      $logger.debug "+++ #{command_name} +++"
      command = @commands[command_name]

      data = command.execute(param_values, extra)

      response = {
        :data => data,
        'context' => nil
      }
    end

    def shutdown()
      $logger.debug "shutting down..."
    end

  end

end
