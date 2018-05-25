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
require_relative "util/worker"

module Vop

  $logger = Logger.new(STDOUT)

  class Vop

    attr_reader :plugins
    attr_reader :commands
    attr_reader :entities

    attr_reader :filters
    attr_reader :filter_chain

    attr_reader :finder, :loader, :sorter

    def initialize(options = {})
      @options = {
        config_path: "/etc/vop",
        log_level: Logger::INFO
      }.merge(options)
      $logger.level = @options[:log_level]

      @finder = PluginFinder.new
      @loader = PluginLoader.new(self)
      @sorter = DependencyResolver.new(self)

      _reset
    end

    def clear
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

    def plugin_locations
      result = []

      # during development, we might find checkouts for "plugins" and "services"
      # next to the core
      vop_dir = Pathname.new(File.join(lib_path, "..", "..")).realpath
      unless vop_dir.to_s.start_with? "/usr"
        %w|plugins services|.each do |thing|
          sibling_dir = File.join(vop_dir, thing)
          result << sibling_dir
        end
      end

      # for distribution packages (?)
      result << "/usr/lib/vop-plugins"

      # an extra path might have been passed in the options
      if @options.has_key? :plugin_path
        result << @options[:plugin_path]
      end

      result
    end

    def config_path
      @options[:config_path]
    end

    def plugin_config_path
      @plugin_config_path ||= File.join(config_path, "plugins.d")
    end

    def executor
      @executor ||= Executor.new(self)
    end

    def load_from(locations, load_options = {})
      found = finder.find(locations)
      plugins = loader.load(found, load_options)
      new_plugins = sorter.sort(plugins.loaded)

      new_plugins.each do |plugin|
        plugin.init
        self << plugin
      end

      $logger.debug "loaded #{new_plugins.size} plugins from #{locations}"
      $logger.debug plugins.loaded.map(&:name)
    end

    def load
      load_from(core_location, { core: true })
      load_from(plugin_locations)
      load_from(search_path)

      call_global_hook :loading_finished

      $logger.info "init complete : #{@plugins.size} plugins, #{@commands.size} commands"
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
          @entities[entity.short_name] = stuff
        elsif stuff.is_a? Command
          command = stuff
          unless command.dont_register
            $logger.debug "registering #{command.name}"
            if @commands.keys.include? command.short_name
              $logger.warn "overriding previous declaration of #{command.short_name}"
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

    def execute_request(request)
      call_global_hook(:before_execute, { request: request })
      begin
        response = request.execute()
      rescue => e
        response = ::Vop::Response.new(nil, {})
        response.status = "error"
        raise e
      ensure
        call_global_hook(:after_execute, { request: request, response: response })
      end

      #$logger.debug "executed : #{request.command.name}, response : #{response.pretty_inspect}"
      response
    end

    def execute(command_name, param_values = {}, extra = {})
      request = Request.new(self, command_name, param_values, extra)
      response = execute_request(request)

      response.result
    end

    def execute_async(request)
      AsyncExecutorWorker.perform_async(request.to_json)
    end

  end

end
