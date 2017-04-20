module Vop

  class DoNotContinue < Exception

    attr_reader :result, :context

    def initialize(result, context)
      @result = result
      @context = context
    end

  end

  class Filter

    attr_reader :name
    attr_reader :plugin

    attr_accessor :description
    attr_accessor :block

    def initialize(plugin, name)
      @plugin = plugin
      @name = name
      @params = []
    end

    def short_name
      @name.split(".").last
    end

    def inspect
      "Vop::Filter #{@name}"
    end

    def execute(command_name, param_values, extra = {}, request = nil)
      block_param_names = self.block.parameters.map { |x| x.last }

      $logger.debug "applying filter [#{self.name}] for #{command_name}"

      payload = []
      context = {} # TODO should this be initialized?

      block_param_names.each do |name|
        param = nil

        param = case name.to_s
        when 'request'
          raise "sanity check failed: request nil" if request.nil?
          request
        when 'command'
          @plugin.op.command(command_name.split(".").first) # TODO shouldn't this be .last ?
        when 'plugin'
          @plugin
        else
          raise "unknown block param name : >>#{name}<<"
        end
        payload << param
      end

      result = nil
      begin
        (result, context) = self.block.call(*payload)
      rescue DoNotContinue => dnc
        result = dnc.result
        context = dnc.context
      end

      [result, context]
    end

    def execute_request(request)
      execute(request.command_name, request.param_values, request.extra, request)
    end

  end

end
