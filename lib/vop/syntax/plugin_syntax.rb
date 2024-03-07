module Vop

  module PluginSyntax

    def resolve_options_string(options)
      if options.is_a? String
        options = {
          description: options
        }
      end
      options
    end

    def config_param(name, options = {})
      options = resolve_options_string(options)

      @plugin.params << CommandParam.new(name, options)
    end

    def config_param!(name, options = {})
      options = resolve_options_string(options)
      options.merge! mandatory: true
      config_param(name, options)
    end



    def description(string)
      @plugin.description = string
    end

    def auto_load(bool)
      @plugin.options[:auto_load] = bool
    end

    def depends_on(others)
      others = [ others ] unless others.is_a?(Array)

      others.each do |other|
        $logger.debug "plugin #{@plugin.name} depends on #{other}"
        @plugin.dependencies << other.to_s
      end
    end

    # TODO: support version requirements
    def depends_on_gem(gem, **options)
      $logger.debug "plugin #{@plugin.name} depends on gem #{gem}"
      @plugin.external_dependencies[:gem] << [gem, options]
    end

    def on(hook_sym, &block)
      @plugin.hook(hook_sym, &block)
    end

    def hook(hook_sym, &block)
      @op.hook(hook_sym, &block)
    end

  end

end
