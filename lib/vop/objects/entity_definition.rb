module Vop

  class EntityDefinition

    attr_reader :plugin, :name
    attr_accessor :description

    attr_accessor :key
    attr_accessor :block
    attr_accessor :on
    attr_accessor :show_options

    attr_accessor :invalidation_block
    attr_accessor :read_only

    def initialize(plugin, name)
      @plugin = plugin
      @name = name
      @key = "name"
      @data = {}

      @block = lambda { |params| $logger.warn "entity #{name} does not have a run block" }
      @invalidation_block = nil

      @on = nil
      @show_options = {}
      @read_only = true
    end

    def short_name
      @name.split(".").last
    end

    def source
      plugin.sources[:entities][name]
    end

    def list_command_name
      short_name.carefully_pluralize
    end

    # this would be necessary if invalidation commands were generated for entities
    # def params
    #   result = []
    #
    #   if @on
    #     result << CommandParam.new(@on.to_s, mandatory: true)
    #   end
    #
    #   result
    # end

  end

end
