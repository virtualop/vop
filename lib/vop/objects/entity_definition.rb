module Vop

  class EntityDefinition

    attr_reader :plugin, :name
    attr_accessor :key
    attr_accessor :block
    attr_accessor :on
    attr_accessor :show_options

    def initialize(plugin, name)
      @plugin = plugin
      @name = name
      @key = "name"
      @data = {}

      @block = lambda { |params| $logger.warn "entity #{name} does not have a run block" }

      @on = nil
      @show_options = {}
    end

    def short_name
      @name.split(".").last
    end

    def source
      plugin.sources[:entities][name]
    end

  end

end
