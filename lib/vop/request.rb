module Vop

  class Request

    attr_reader :command_name, :param_values, :extra

    def initialize(op, command_name, param_values = {}, extra = {})
      @command_name = command_name
      @param_values = param_values
      @extra = extra
      @op = op

      @current_filter = nil
      @filter_chain = @op.filter_chain.clone
    end

    def command
      @op.command(@command_name)
    end

    def param(name)
      command.params.select { |x| x[:name] == name }.first
    end

    def cache_key
      blacklist = %w|shell raw_params|

      prepared = command.prepare_params(@param_values, @extra)
      param_string = prepared.map { |k,v|
        unless blacklist.include? k
          [k,v].join("=")
        end
      }.compact.join(":")
      "vop/request:#{command.name}:" + param_string + ":v1"
    end

    def next_filter
       @chain.next()
    end

    def execute
      result = nil
      context = nil

      # build a chain out of all filters + the command itself
      command = @op.commands[command_name]
      filter_chain = @op.filter_chain.clone.map {
        |filter_name| @op.filters[filter_name.split(".").first]
      }
      filter_chain << command
      @chain = Chain.new(@op, filter_chain)
      @chain.execute(self)
    end

  end

  class Response

    attr_reader :result, :context
    attr_accessor :status

    def initialize(result, context)
      @result = result
      @context = context
      @status = "ok"
    end

  end

  class Chain

    attr_reader :links

    def initialize(op, links)
      @op = op
      @links = links
    end

    def next
      @links.shift
    end

    def execute(request)
      next_link = self.next
      if next_link
        (@result, @context) = next_link.execute_request(request)
      end
      Response.new(@result, @context)
    end

  end

end
