module Vop

  class Command

    attr_reader :name
    attr_reader :plugin

    attr_accessor :block
    attr_accessor :description
    attr_accessor :show_options

    attr_reader :params

    def initialize(plugin, name)
      @plugin = plugin
      @name = name
      @block = lambda { |params| $logger.warn "#{name} not yet implemented!" }
      @params = []
      @show_options = {}
    end

    def inspect
      "Vop::Command #{@name}"
    end

    def source
      @plugin.command_source(name)
    end

    def short_name
      name.split(".").last
    end

    def param(name)
      params.select { |param| param[:name] == name }.first || nil
    end

    # the default param is the one used when a command is called with a single "scalar" param only, like
    #   @op.foo("zaphod")
    # if a parameter is marked as default, it will be assigned the value "zaphod" in this case.
    # if there's only a single param, it's the default param by default (ha!)
    def default_param
      if params.size == 1
        params.first
      else
        params.select { |param| param[:default_param] == true }.first || nil
      end
    end

    def mandatory_params
      params.select do |p|
        p[:mandatory]
      end
    end

    def lookup(param_name, params)
      p = param(param_name)
      raise "no such param : #{param_name} in command #{name}" unless p

      if p.has_key? :lookup
        p[:lookup].call(params)
      else
        $logger.debug "no lookups for #{param_name}"
        []
      end
    end

    # accepts arguments as handed in by :define_method and prepares them
    # into the +params+ structure expected by command blocks
    def prepare_params(ruby_args, extra = {})
      result = {}
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
            end
            result[k] = v
          end
        else
          # if there's a default param, it can be passed as "scalar" param
          # (as opposed to the usual hash) to execute, but will be converted
          # into a "normal" named param
          dp = default_param
          if dp
            result = {dp[:name] => ruby_args}
          end
        end
      end

      if extra.keys.size > 0
        result.merge! extra
      end

      # add in defaults (for all params that have not been specified)
      params.each do |p|
        unless result.has_key? p[:name]
          if p[:default]
            result[p[:name]] = p[:default]
          end
        end
      end

      result
    end

    def execute(param_values, extra = {})
      prepared = prepare_params(param_values, extra)

      block_param_names = self.block.parameters.map { |x| x.last }

      #puts "executing #{self.name} : prepared : #{prepared.inspect}"

      payload = []
      context = {} # TODO should this be initialized?

      block_param_names.each do |name|
        param = nil

        case name.to_s
        when 'params'
          param = prepared
        when 'plugin'
          param = self.plugin
        when 'context'
          param = context
        when 'shell'
          raise "shell not supported" unless extra.has_key? 'shell'
          param = extra['shell']
        else
          if prepared.has_key? name.to_s
            param = prepared[name.to_s]
          elsif prepared.has_key? name
            param = prepared[name]
          else
            raise "unknown block param name : >>#{name}<<"
          end
        end

        # from the black magick department: block parameters with the
        # same name as an entity get auto-inflated
        if param
          if @plugin.op.list_entities.include? name.to_s
            resolved = @plugin.op.send(name, param)
            param = resolved
          end
          payload << param
        end
      end

      result = self.block.call(*payload)
      [result, context]
    end

  end

end
