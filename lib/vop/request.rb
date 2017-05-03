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

    # accepts arguments as handed in by :define_method and prepares them
    # into the +params+ structure expected by command blocks
    # TODO merge with similar looking code in Command
    def prepare
      result = {}

      ruby_args = @param_values

      if ruby_args
        if ruby_args.is_a? Hash
          result = ruby_args
          ruby_args.each do |k,v|
            p = param(k)
            if p
              # values are auto-boxed into an array if the param expects multiple values
              if p[:multi] && ! v.is_a?(Array) then
                $logger.debug("autoboxing for #{p[:name]}")
                v = [ v ]
              # array values are auto-unboxed if the param doesn't want multi
              elsif ! p[:multi] && v.is_a?(Array) && v.length == 1
                $logger.debug("autounboxing for #{p[:name]}")
                v = v.first
              end

              # convert booleans
              if p[:boolean]
                $logger.info("converting #{p[:name]} into boolean")
                v = /[tT]rue|[yY]es|[oO]n/ =~ v
              end
            end
            result[k] = v
          end
        else
          # if there's a default param, it can be passed to execute as "scalar"
          # param, but it will be converted into a "normal" named param
          dp = command.default_param
          result = {
            dp[:name] => ruby_args
          } if dp
        end
      end

      if @extra.keys.size > 0
        result.merge! @extra
      end

      # add in defaults (for all params that have not been specified)
      command.params.each do |p|
        unless result.has_key? p[:name]
          if p.has_key? :default
            result[p[:name]] = p[:default]
          end
        end
      end

      result
    end

    def cache_key
      blacklist = %w|shell raw_params|
      param_string = prepare.map { |k,v|
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

    def initialize(result, context)
      @result = result
      @context = context
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
