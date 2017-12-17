require_relative "command_param"

module Vop

  class Command

    attr_accessor :name
    attr_accessor :block
    attr_accessor :params
    attr_accessor :plugin
    attr_accessor :show_options
    attr_accessor :description
    attr_accessor :dont_register
    attr_accessor :read_only

    def initialize(plugin, name)
      @plugin = plugin
      @name = name
      @description = nil

      @block = lambda { |params| $logger.warn "#{name} not yet implemented!" }

      @params = []
      @show_options = {}

      @dont_register = false
      @read_only = false
    end

    def short_name
      @name.split(".").last
    end

    def source
      plugin.sources[:commands][name]
    end

    def param(name)
      @params.select { |x| x.name == name }.first
    end

    def add_param(name, options = {})
      @params << CommandParam.new(name, options)
    end

    def params_with(&filter)
      params.select do |param|
        filter.call(param)
      end
    end

    def mandatory_params
      params_with { |x| x.options[:mandatory] == true }
    end

    # The default param is the one used when a command is called with a single "scalar" param only, like
    #   @op.foo("zaphod")
    # If a parameter is marked as default, it will be assigned the value "zaphod" in this case.
    # If there is only a single param, it is the default param by default
    # Also, if there is only one mandatory param, it is considered to be the default param
    def default_param
      if params.size == 1
        params.first
      else
        result = params_with { |x| x.options[:default_param] == true }.first
        if result.nil?
          mandatory = mandatory_params
          if mandatory_params.size == 1
            result = mandatory.first
          end
        end
        result
      end
    end

    def execute(payload)
      self.block.call(*payload)
    end

  end

end
