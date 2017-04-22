require 'active_support/inflector'
require 'json'
require 'logger'
require 'pathname'
require 'pp'
require 'yaml'

require_relative 'vop/helpers/dependency_resolver'
require_relative 'vop/helpers/plugin_finder'
require_relative 'vop/loaders/plugin_loader'
require_relative 'vop/loaders/filter_loader'
require_relative 'vop/request'
require_relative 'vop/version'

module Vop

  VOP_ROOT = Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath
  CORE_PLUGIN_PATH = File.join(VOP_ROOT, "lib", "vop", "plugins")

  class Vop

    DEFAULTS = {
      search_path: [],
      config_path: "/etc/vop"
    }

    attr_reader :config

    attr_reader :plugins
    attr_reader :commands, :filters, :filter_chain

    def initialize(options = {})
      at_exit {
        self.shutdown
      }

      @version = ::Vop::VERSION

      @config_path = options[:config_path] || DEFAULTS[:config_path]
      system_config = load_system_config()
      @config = DEFAULTS.merge(system_config).merge(options)

      if options.has_key? :search_path
        osp = options[:search_path]
        osp = [ osp ] unless osp.is_a?(Array)
        @config[:search_path] += osp
      end

      $logger = Logger.new(STDOUT)
      $logger.level = options['--verbose'] || options[:verbose] ? Logger::DEBUG : Logger::INFO

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
      clear && load_thyself
      $logger.info "loaded #{@commands.size} commands from #{@plugins.size} plugins"
    end

    def shutdown()
      $logger.debug "shutting down..."
    end

    def clear
      @plugins = {}
      @commands = {}
      @filters = {}
      @filter_chain = []
      @hooks = Hash.new { |h,k| h[k] = [] }
    end

    def core_path
      [ CORE_PLUGIN_PATH ] + # static path
      config[:search_path] # config from /etc/vop
    end

    def search_path
      result = []

      if core && core.config && core.config[:search_path]
        result += core.config[:search_path] # core plugin config
      end

      result
    end

    def add_to_search_path(new_path)
      core.config ||= {}
      core.config[:search_path] ||= []
      core.config[:search_path] << new_path
    end

    def plugin_config_path
      @plugin_config_path ||= File.join(@config_path, "plugins.d")
    end

    def command(name)
      unless @commands.has_key?(name)
        raise "no such command : #{name}"
      end

      @commands[name]
    end

    def core
      @plugins['core']
    end

    def load_system_config
      if File.exists? @config_path
        main_config_root = File.join(@config_path, 'vop.')

        result = if File.exists? main_config_root + 'yml'
          YAML.load_file(main_config_root + 'yml')
        elsif File.exists? main_config_root + 'json'
          JSON.parse(IO.read(main_config_root + 'json'))
        else
          {}
        end
      end
    end

    # loads Plugins, Commands and Filters (or arrays of them)
    def eat(stuff)
      if stuff.is_a? Array
        inspected = [stuff.inspect, "#{stuff.size} elements"].join(" ")
        $logger.debug "eating #{inspected}"
        stuff.each do |thing|
          eat(thing)
        end
      else
        $logger.debug "eating #{stuff.inspect}"
        if stuff.is_a? Plugin
          @plugins[stuff.name] = stuff
          stuff.init
        elsif stuff.is_a? Command
          command = stuff
          @commands[command.short_name] = command

          self.class.send(:define_method, command.short_name) do |*args|
            ruby_args = args.length > 0 ? args[0] : {}
            self.execute(command.short_name, ruby_args)
          end
        elsif stuff.is_a? Filter
          short_name = stuff.short_name
          @filters[stuff.short_name] = stuff
          @filter_chain.unshift stuff.short_name
        else
          raise "don't know how to process #{stuff.class}"
        end
      end
    end

    def load_from(path)
      $logger.debug "loading from #{path.join(" ")}"

      # step 1 : find and load plugins
      (plugins, templates) = PluginFinder.find(self, path)
      fresh = PluginLoader.read(self, plugins, templates)

      # step 2 : activate new plugins (in the right order)
      fresh_loaded = fresh.loaded.map { |plugin| [plugin.name, plugin] }.to_h
      all_plugins = @plugins.merge(fresh_loaded)
      DependencyResolver.order(self, all_plugins).each do |plugin|
        if fresh.loaded.include? plugin
          eat(plugin)
        end
      end

      # step 3 : expand entities
      @plugins['core'].state[:entities].each do |entity|
        entity_name = entity[:name]
        entity_command = @commands[entity_name]

        # list_<entities>
        list_command_name = "list_#{entity_name.pluralize(42)}"
        $logger.debug "generating entity command #{list_command_name}"
        list_command = Command.new(entity_command.plugin, list_command_name)
        list_command.read_only = true

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
    end

    def load_thyself
      load_from core_path
      load_from search_path unless search_path.empty?

      new_paths = self.search_gems_for_plugins
      new_paths.each do |new_path|
        $logger.info "found new gem plugins, adding #{new_path} to the search path..."
        self.add_search_path new_path
      end unless new_paths.nil?
    end

    def hook(name, plugin_name)
      @hooks[name] << plugin_name
    end

    def call_hook(name, *payload)
      @hooks[name].each do |plugin_name, block|
        @plugins[plugin_name].call_hook(name, payload)
      end
    end

    def execute_request(request)
      call_hook :before_execute, request
      response = request.execute()
      call_hook :after_execute, request, response

      response
    end

    def execute(command_name, param_values = {}, extra = {})
      request = Request.new(self, command_name, param_values, extra)
      response = execute_request(request)

      response.result
    end

    def inspect
      chunk_size = 25
      plugins = @plugins || {}
      plugin_string = plugins.keys.sort[0..chunk_size-1].join(' ')
      if plugins.length > chunk_size
        plugin_string += " + #{plugins.length - chunk_size} more"
      end
      "vop #{@version} (#{plugin_string})"
    end

  end

end
