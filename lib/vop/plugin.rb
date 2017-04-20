require "erb"
require_relative "command_loader"
require_relative "helpers/symbolize_helper"
using SymbolizeHelper

module Vop
  class Plugin

    attr_reader :op
    attr_reader :name
    attr_reader :path
    attr_reader :options

    attr_reader :commands
    attr_accessor :config
    attr_reader :dependencies

    attr_reader :state
    attr_reader :loaded

    def initialize(op, plugin_name, plugin_path, options = {})
      @op = op
      @name = plugin_name
      @path = plugin_path
      defaults = {
        autoload: true
      }
      @options = defaults.merge(options)

      @loaded = false

      @config = nil
      @dependencies = []

      @config_file_name = File.join(op.plugin_config_path, plugin_name + ".json")

      # all plugins depend on "core" (unless they are core or some murky dummy called __root__)
      independents = %w|core __root__|
      @dependencies << "core" unless independents.include? plugin_name

      @state = {}
      @hooks = {}

      @sources = Hash.new { |h, k| h[k] = {} }
    end

    def inspect
      "Vop::Plugin #{@name}"
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

    def init
      $logger.debug "plugin init : #{@name}"
      call_hook :preload
      load_helpers
      load_config

      if @options[:autoload] || @config
        # TODO we might want to activate/register only plugins with enough config
        call_hook :init
        load_commands
        load_filters
        call_hook :activate
        @loaded = true
      end
    end

    def plugin_dir(name)
      File.join(@path, name.to_s)
    end

    def load_code_from_dir(type_name)
      dir = plugin_dir type_name
      if File.exists?(dir)
        Dir.glob(File.join(dir, '*.rb')).each do |file_name|
          name_from_file = /#{dir}\/(.+).rb$/.match(file_name).captures.first
          full_name = @name + '.' + name_from_file
          $logger.debug("  #{type_name} << #{full_name}")

          code = File.read(file_name)
          @sources[type_name][full_name] = {
            :file_name => file_name,
            :code => code
          }
        end
      else
        #$logger.debug "no #{type_name} dir found - checked for #{dir}"
      end
    end

    def load_helpers
      load_code_from_dir 'helpers'
      load_code_from_dir 'helpers/command_loader'
      load_code_from_dir 'helpers/plugin_loader'
    end

    def helper_sources(type_name = 'helpers')
      @sources[type_name].map do |name, source|
        source[:code]
      end
    end

    def command_source(command_name)
      @sources[:commands][command_name]
    end

    def inject_helpers(target, sub_type_name = nil)
      type_name = 'helpers'
      if sub_type_name
        type_name += '/' + sub_type_name
      end

      plugins_to_load_helpers_from = [ self ]

      self.dependencies.each do |name|
        other = @op.plugins[name]
        raise "can not resolve plugin dependency #{name}" unless other
        plugins_to_load_helpers_from << other
      end

      plugins_to_load_helpers_from.each do |other_plugin|
        next if other_plugin.helper_sources(type_name).size == 0
        #$logger.debug "loading helper from #{other_plugin.name} into #{target} : #{other_plugin.helper_sources.size}"

        helper_module = Module.new()
        other_plugin.helper_sources(type_name).each do |source|
          helper_module.class_eval source
        end
        target.extend helper_module
      end
    end

    def load_commands
      load_code_from_dir :commands

      loader = CommandLoader.new(self)
      @commands = loader.read_sources @sources[:commands]
      @commands.each do |name, command|
        # TODO might want to warn/debug about overrides here
        @op.eat(command)
      end
    end

    def load_filters
      load_code_from_dir :filters

      loader = FilterLoader.new(self)
      @filters = loader.read_sources @sources[:filters]
      @op.eat(@filters.values) unless @filters.size == 0
    end

    def load_config
      if File.exists? @config_file_name
        raw = nil
        begin
          raw = IO.read(@config_file_name)
          @config = JSON.parse(raw).deep_symbolize_keys
        rescue => e
          $logger.error "could not read JSON config from #{@config_file_name} (#{e.message}), ignoring:\n#{raw}"
        end
      end
    end

    def write_config
      unless File.exists? @op.plugin_config_path
        FileUtils.mkdir_p @op.plugin_config_path
      end
      File.open(@config_file_name, 'w') do |file|
        file.write @config.to_json()
      end
    end

    def read_template(sym)
      path = File.join(self.path, "templates", sym.to_s + ".erb")
      $logger.debug "reading plugin template #{sym} from #{path}"
      renderer = ERB.new(IO.read(path))
      renderer.result(binding)
    end

  end
end
