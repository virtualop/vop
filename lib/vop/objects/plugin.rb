require "json"
require_relative "../parts/entity_loader"
require_relative "../parts/command_loader"
require_relative "../parts/filter_loader"

module Vop

  class Plugin

    attr_reader :op
    attr_reader :name
    attr_accessor :description
    attr_reader :options
    attr_reader :commands

    attr_reader :sources
    attr_reader :state
    attr_reader :config
    attr_accessor :dependencies

    def initialize(op, plugin_name, plugin_path, options = {})
      @op = op
      @name = plugin_name
      @path = plugin_path

      defaults = {
        auto_load: true
      }
      @options = defaults.merge(options)

      @description = nil

      @state = {}

      @config_file_name = File.join(op.plugin_config_path, plugin_name + ".json")
      @config = {}

      @dependencies = []

      @hooks = {}
    end

    def to_s
      "Vop::Plugin #{name}"
    end

    def init
      $logger.debug "plugin init : #{@name}"

      @sources = Hash.new { |h, k| h[k] = {} }

      # call_hook :preload ?
      load_helpers
      load_config

      # TODO proceed only if auto_load
      call_hook :init
      load_entities
      load_commands
      load_filters

      #@op.call_global_hook :plugin_loaded, self
    end

    def plugin_dir(name)
      File.join(@path, name.to_s)
    end

    def load_config
      $logger.debug "looking for config at #{@config_file_name}"
      if File.exists? @config_file_name
        raw = nil
        begin
          raw = IO.read(@config_file_name)
          @config = JSON.parse(raw)
          $logger.debug "plugin config loaded from #{@config_file_name}"
        rescue => e
          $logger.error "could not read JSON config from #{@config_file_name} (#{e.message}), ignoring:\n#{raw}"
        end
      end
    end

    def write_config
      $logger.info "writing config into #{@op.plugin_config_path}"
      unless Dir.exists?(@op.plugin_config_path)
        FileUtils.mkdir_p @op.plugin_config_path
      end
      File.open(@config_file_name, "w") do |file|
        file.write @config.to_json()
      end
    end

    def load_code_from_dir(type_name)
      dir = plugin_dir(type_name)

      if File.exists?(dir)
        Dir.glob(File.join(dir, "*.rb")).each do |file_name|
          name_from_file = /#{dir}\/(.+).rb$/.match(file_name).captures.first
          full_name = [@name, name_from_file].join(".")
          $logger.debug("  #{type_name} << #{full_name}")

          @sources[type_name][full_name] = {
            :file_name => file_name,
            :code => File.read(file_name)
          }
        end
      end
    end

    def load_entities
      loader = EntityLoader.new(self)

      load_code_from_dir :entities
      @entities = loader.read_sources @sources[:entities]
      @op << @entities unless @entities.empty?
    end

    def load_commands
      loader = CommandLoader.new(self)

      load_code_from_dir :commands
      @commands = loader.read_sources @sources[:commands]
      @op << @commands unless @commands.empty?
    end

    def load_filters
      loader = FilterLoader.new(self)

      load_code_from_dir :filters
      @filters = loader.read_sources @sources[:filters]
      @op << @filters unless @filters.empty?
    end

    def load_helpers
      #load_code_from_dir :helpers
      load_code_from_dir("helpers") # TODO unify (symbol vs. string) with load_commands above
    end

    def inject_helpers(target, sub_type_name = nil)
      type_name = 'helpers'

      plugins_to_load_helpers_from = [ self ]

      self.dependencies.each do |name|
        other = @op.plugin(name)
        raise "can not resolve plugin dependency #{name}" unless other
        plugins_to_load_helpers_from << other
      end

      plugins_to_load_helpers_from.each do |other_plugin|
        helper_sources = other_plugin.sources[type_name]

        next if helper_sources.size == 0

        helper_module = Module.new()

        helper_sources.each do |name, helper|
          begin
            helper_module.class_eval helper[:code]
          rescue Exception => e
            $stderr.puts("could not read helper #{name} : #{e.message}")
            raise e
          end
        end

        target.extend helper_module
      end
    end

    def hook(name, &block)
      @hooks[name.to_sym] = block
    end

    def call_hook(name, *args)
      result = nil
      if @hooks.has_key? name
        result = @hooks[name].call(self, *args)
      end
      result
    end

  end

end