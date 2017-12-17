module Vop

  module PluginSyntax

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

    def on(hook_sym, &block)
      @plugin.hook(hook_sym, &block)
    end

    def hook(hook_sym, &block)
      @op.hook(hook_sym, &block)
    end

  end

end
