require 'pp'
require 'logger'
require 'pathname'
require 'yaml'
require 'json'

require 'vop/version'
require 'vop/plugin_loader'
require 'active_support/inflector'

module Vop

  VOP_ROOT = Pathname.new(File.join(File.dirname(__FILE__), '..')).realpath
  CORE_PLUGIN_PATH = Pathname.new(File.join(File.dirname(__FILE__), 'vop', 'plugins')).realpath
  CONFIG_PATH = '/etc/vop'
  PLUGIN_CONFIG_PATH = File.join(CONFIG_PATH, 'plugins.d')

  class Vop

    DEFAULTS = {
      'search_path' => [
        File.join(VOP_ROOT, '..', 'plugins/standard'),
        File.join(VOP_ROOT, '..', 'plugins/extended')
      ]
    }

    attr_reader :config

    attr_reader :plugins
    attr_reader :commands

    def initialize(options = {})
      at_exit {
        self.shutdown
      }

      @version = ::Vop::VERSION

      @plugins = {}
      @commands = {}
      @hooks = Hash.new { |h,k| h[k] = [] }

      @config = DEFAULTS
      @config.merge! load_system_config
      @config.merge! options

      if options.has_key? :search_path
        osp = options[:search_path]
        @config['search_path'] = osp.is_a?(Array) ? osp : [ osp ]
      end

      $logger = Logger.new(STDOUT)
      $logger.level = options['--verbose'] ? Logger::DEBUG : Logger::INFO

      $logger.debug "config : #{@config.inspect}"

      _reset

      $logger.info "virtualop (#{@version}) init complete."
      $logger.info "hello."
    end

    def _pry
      binding.pry
    end

    def _reset
      $logger.debug "loading..."

      load_plugins_twice

      $logger.info "loaded #{@commands.size} commands from #{@plugins.size} plugins"
    end

    def _search_path
      result = [ CORE_PLUGIN_PATH ] + config['search_path']
      if @plugins.has_key?('core') && ! @plugins['core'].config.nil? && @plugins['core'].config.has_key?('search_path')
        result += @plugins['core'].config['search_path']
      end
      result
    end

    def add_to_search_path(new_path)
      core.config['search_path'] ||= []
      core.config['search_path'] << new_path
    end

    def load_system_config
      if File.exists? CONFIG_PATH
        main_config_root = File.join(CONFIG_PATH, 'vop.')

        result = if File.exists? main_config_root + 'yml'
          YAML.load_file(main_config_root + 'yml')
        elsif File.exists? main_config_root + 'json'
          JSON.parse(IO.read(main_config_root + 'json'))
        else
          {}
        end
      end
    end

    def inspect
      chunk_size = 25
      plugin_string = @plugins.keys.sort[0..chunk_size-1].join(' ')
      if @plugins.length > chunk_size
        plugin_string += " + #{@plugins.length - chunk_size} more"
      end
      "vop #{@version} (#{plugin_string})"
    end

    def eat(command)
      @commands[command.short_name] = command

      self.class.send(:define_method, command.short_name) do |*args|
        ruby_args = args.length > 0 ? args[0] : {}
        self.execute(command.short_name, ruby_args)
      end
    end

    def load_plugins
      @plugins = {}
      @commands = {}
      @hooks = Hash.new { |h,k| h[k] = [] }

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

      # step 3 : expand entities
      @plugins['core'].state[:entities].each do |entity|
        entity_name = entity[:name]
        entity_command = @commands[entity_name]
        list_command_name = "list_#{entity_name.pluralize(42)}"
        $logger.debug "generating #{list_command_name}"
        list_command = Command.new(entity_command.plugin, list_command_name)

        if entity[:options][:on]
          list_command.params << {
            :name => entity[:options][:on],
            :multi => false,
            :mandatory => true,
            :default_param => true
          }
        end
        list_command.block = entity_command.param(entity[:key])[:lookup]
        eat(list_command)
        # TODO add pseudo source code so that `source <list_command_name>` works
      end

      # TODO add pre-flight hook so that plugins can attach logic to execute here
    end

    # plugins are configured when they are loaded; the search path is part of the
    # 'core' plugin's config, so we load plugins again with a potentially
    # extended search path
    def load_plugins_twice
      first_search_path = _search_path
      load_plugins
      second_search_path = _search_path
      if second_search_path != first_search_path
        #load_plugins
      end
      third_search_path = _search_path
      if third_search_path != second_search_path
        $logger.warn "search path changed again during second load, not falling for it."
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

    def core
      @plugins['core']
    end

    def hook(name, plugin_name)
      @hooks[name] << plugin_name
    end

    def call_hook(name, *payload)
      @hooks[name].each do |plugin_name, block|
        @plugins[plugin_name].call_hook(name, payload)
      end
    end

    def before_execute(request)
      #puts ">> #{request.command_name} #{request.param_values.keys}"
      call_hook :before_execute, request
    end

    def after_execute(request, response)
      #puts "<< #{request.command_name} #{response.result}"
      call_hook :after_execute, request, response
    end

    def execute(command_name, param_values = {}, extra = {})
      request = Request.new(command_name, param_values, extra)
      before_execute(request)

      (result, context) = execute_command(command_name, param_values, extra)

      response = Response.new(result, context)
      after_execute(request, response)

      result
    end

    def execute_command(command_name, param_values, extra = {})
      $logger.debug "+++ #{command_name} +++"
      command = @commands[command_name]

      command.execute(param_values, extra)
    end

    def shutdown()
      $logger.debug "shutting down..."
    end

  end

  class Request

    attr_reader :command_name, :param_values

    def initialize(command_name, param_values, extra = {})
      @command_name = command_name
      @param_values = param_values
      # fuck extra
    end

  end

  class Response

    attr_reader :result

    def initialize(result, context)
      @result = result
      @context = context
    end

  end


end
