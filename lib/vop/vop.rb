require "pathname"
require "pp"
require "logger"

require_relative "parts/plugin_finder"
require_relative "parts/plugin_loader"
require_relative "parts/dependency_resolver"
require_relative "objects/request"
require_relative "objects/entity"
require_relative "objects/entities"
require_relative "util/errors"
require_relative "util/pluralizer"

module Vop

  $logger = Logger.new(STDOUT)

  class Vop

    attr_reader :plugins
    attr_reader :commands
    attr_reader :entities

    attr_reader :filters
    attr_reader :filter_chain

    attr_reader :finder, :loader, :sorter
    attr_reader :search_path
    attr_reader :load_status

    @search_path = []

    def initialize(options = {})
      @options = {
        config_path: "/etc/vop",
        log_level: Logger::INFO,
        no_init: false,
      }.merge(options)
      $logger.level = @options[:log_level]

      @finder = PluginFinder.new
      @loader = PluginLoader.new(self)
      @sorter = DependencyResolver.new(self)

      _reset
    end

    def clear
      @load_status = {}
      @plugins = []
      @commands = {}
      @entities = {}
      @filters = {}
      @filter_chain = []
      @hooks = Hash.new { |h,k| h[k] = [] }
    end

    def _reset
      clear
      load
      init unless @options[:no_init]
    end

    def to_s
      "Vop (#{@plugins.size} plugins)"
    end

    def inspect
      {
        plugins: @plugins.map(&:name)
      }.to_json()
    end

    def plugin(name)
      result = @plugins.select { |x| x.name == name }.first
      raise "no such plugin: #{name}" if result.nil?
      result
    end

    def lib_path
      Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath
    end

    def core_location
      File.join(lib_path, "core")
    end

    def config_path
      @options[:config_path]
    end

    def plugin_config_path
      @plugin_config_path ||= File.join(config_path, "plugins.d")
    end

    def search_path_config_dir
      @search_path_config_dir ||= File.join(config_path, "search_path.d")
    end

    def executor
      @executor ||= Executor.new(self)
    end

    def search_path
      unless @assembled_search_path
        @assembled_search_path = self.class.search_path
        unless ENV["VOP_IGNORE_PLUGINS"]
          @assembled_search_path += Dir.glob("#{search_path_config_dir}/*").map { |x| File.readlink(x) }
        end
      end
      @assembled_search_path
    end

    def unloaded
      search_path.reject { |path| @load_status.key? path }
    end

    def load
      load_from(core_location, { core: true })
      load_from(@options[:plugin_path]) if @options.has_key?(:plugin_path)

      while unloaded.any? do
        unloaded.each do |path|
          $logger.debug "loading from #{path}..."
          load_from path
          @load_status[path] = true
        rescue => e
          @load_status[path] = false
          $logger.error "could not load plugins from #{path} : #{e.message}"
          raise
        end
      end

      # TODO: do we need this?
      # call_global_hook :loading_finished
      $logger.debug "loaded : #{@plugins.size} plugins, #{@commands.size} commands"
    end

    def load_from(locations, load_options = {})
      found = finder.find(locations)
      plugins = loader.load(found, load_options)
      new_plugins = sorter.sort(plugins.loaded)

      new_plugins.each do |plugin|
        plugin.load
        self << plugin
      end

      $logger.debug "loaded #{new_plugins.size} plugins from #{locations}"
      $logger.debug plugins.loaded.map(&:name)
    end

    def init
      @plugins.each(&:init)
      call_global_hook :init_complete
    end

    def <<(stuff)
      if stuff.is_a? Array
        stuff.each do |thing|
          self << thing
        end
      else
        if stuff.is_a? Plugin
          @plugins << stuff
        elsif stuff.is_a? EntityDefinition
          entity = stuff
          # TODO : auto-merge entities with the same name from multiple plugins?
          @entities[entity.short_name] = stuff
        elsif stuff.is_a? Command
          command = stuff
          unless command.dont_register
            $logger.debug "registering #{command.name}"
            if @commands.keys.include? command.short_name
              $logger.debug "overriding previous declaration of #{command.short_name}"
            end
            @commands[command.short_name] = stuff

            self.class.send(:define_method, command.short_name) do |*args, &block|
              ruby_args = args.length > 0 ? args[0] : {}
              # TODO we might want to do this only if there's a block param defined
              if block
                ruby_args["block"] = block
              end
              self.execute(command.short_name, ruby_args)
            end
          end
        elsif stuff.is_a? Filter
          short_name = stuff.short_name
          @filters[short_name] = stuff
          @filter_chain.unshift short_name
        else
          raise Errors::LoadError.new "unexpected type '#{stuff.class}'"
        end
      end
    end

    def hook(hook_sym, &block)
      @hooks[hook_sym] << block
    end

    def call_global_hook(hook_sym, payload = {})
      @hooks[hook_sym].each do |h|
        h.call(payload)
      end

      @plugins.each do |plugin|
        if plugin.has_hook? hook_sym
          plugin.call_hook(hook_sym, payload)
        end
      end
    end

    def prepare_request(command_name, param_values = {}, extra = {}, origin_suffix = nil)
      request = Request.new(self, command_name, param_values, extra)
      request.origin = "#{@options[:origin]}"
      request.origin += ":#{origin_suffix}" unless origin_suffix.nil?
      request
    end

    def execute_request(request)
      call_global_hook(:before_execute, { request: request })
      begin
        response = request.execute()
      rescue => e
        response = Response.new(nil, {})
        response.status = "error"
        raise e
      ensure
        call_global_hook(:after_execute, { request: request, response: response })
      end

      response
    end

    def execute(command_name, param_values = {}, extra = {})
      request = prepare_request(command_name, param_values, extra)
      response = execute_request(request)
      response.result
    end

    def self.search_path
      @search_path
    end
  end
end
