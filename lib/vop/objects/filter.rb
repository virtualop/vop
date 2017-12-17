module Vop

  class Filter

    attr_reader :name, :plugin

    attr_accessor :description
    attr_accessor :block

    def initialize(plugin, name)
      @plugin = plugin
      @name = name
    end

    def short_name
      @name.split(".").last
    end

    def execute(request)
      # this executor is just to prepare payload
      ex = Executor.new(@plugin.op)
      context = {}
      block_param_names = self.block.parameters.map { |x| x.last }
      payload = ex.prepare_payload(request, context, block_param_names)

      response = nil
      begin
        response = self.block.call(*payload)
      rescue InterruptChain => ic
        response = ic.response
      end

      response
    end

  end  

  class InterruptChain < Exception

    attr_reader :response

    def initialize(response)
      @response = response
    end

  end

end
