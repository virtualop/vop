module Vop

  class Executor

    def initialize(vop)
      @op = vop
    end

    # accepts arguments as handed in by :define_method and prepares them
    # into the +params+ structure expected by command blocks
    def prepare_params(request)
      (ruby_args, extra) = request.param_values, request.extra
      result = {}
      if ruby_args
        if ruby_args.is_a? Hash
          result = ruby_args
        else
          # if there is a default param, it can be passed to execute as "scalar"
          # param, but it will be converted into a "normal" named param
          dp = request.command.default_param
          if dp
            result = {
              dp.name => ruby_args
            }
          end
        end
      end

      if extra.keys.size > 0
        extra.each do |k,v|
          param = request.command.param(k)
          # TODO actually, this is not always context - it's used from the entities as well
          if param && param.wants_context
            result[k] = extra[k]
          end
        end
      end

      # add in defaults (for all params that have not been specified)
      request.command.params.each do |p|
        param_name = p.name.to_sym
        unless result.has_key? param_name
          if p.options.has_key? :default
            result[param_name] = p.options[:default]
          end
        end
      end

      result.each do |k,v|
        param = request.command.param(k.to_s)
        if param.nil? && ! request.command.allows_extra
          raise "no such param #{k.to_s} (in #{request.command.name})"
        end
        p = param && param.options
        if p
          # values are auto-boxed into an array if the param expects multiple values
          if p[:multi] && ! v.is_a?(Array) then
            v = [ v ]
          # array values are auto-unboxed if the param does not want multi
          elsif ! p[:multi] && v.is_a?(Array) && v.length == 1
            v = v.first
          end

          # convert booleans
          if p[:boolean] && ! v.nil?
            unless [true, false].include? v
              #$logger.debug("converting #{param.name} (#{v}) into boolean")
              v = !! /[tT]rue|[yY]es|[oO]n/.match(v)
            end
          end
        end
        result[k] = v
      end

      result
    end

    def prepare_payload(request, context, block_param_names)
      payload = []

      prepared = prepare_params(request)
      param_names = request.command.params.map { |x| x.name }

      block_param_names.each do |name|
        param = nil

        case name.to_s
        when "params"
          param = prepared
        when "plugin"
          param = request.command.plugin
        when "command"
          param = request.command
        when "request"
          param = request
        when "context"
          param = context
        when "shell"
          raise "shell not supported" if request.shell.nil?
          param = request.shell
        else
          if prepared.has_key? name.to_s
            param = prepared[name.to_s]
          elsif prepared.has_key? name
            param = prepared[name]
          else
            unless param_names.include? name.to_s
              raise "unknown block param name : >>#{name}<<"
            end
          end
        end

        unless param.nil?
          command_param = request.command.param(name.to_s)
          if command_param && command_param.options[:entity]
            # auto-inflate entities
            entity_list = @op.entities.values
            entity = entity_list.select { |x| x.short_name == name.to_s }.first

            unless entity.nil?
              #$logger.debug "auto-inflating entity #{name.to_s} (#{param})"

              list_command_name = entity.short_name.carefully_pluralize
              the_list = @op.execute(list_command_name, {})
              #$logger.debug "inflated entity list : #{the_list.size} entities"
              param = the_list.select { |x| x[entity.key] == param }.first
            end
          end

          payload << param
        end
      end

      payload
    end

    def execute(request)
      blacklist = %w|list_contributors collect_contributions machines rails_machines|
      unless blacklist.include? request.command.short_name
        $logger.debug "+++ #{request.command.short_name} (#{request.param_values}) +++"
      end
      command = request.command

      context = {}
      block_param_names = request.command.block.parameters.map { |x| x.last }
      payload = prepare_payload(request, context, block_param_names)
      result = command.execute(payload)

      Response.new(result, context)
    end

  end


end
