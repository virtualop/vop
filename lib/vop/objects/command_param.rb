module Vop

  class CommandParam

    attr_reader :name, :options

    def initialize(name, options = {})
      @name = name

      unless options.is_a? Hash
        raise "[CommandParam] sanity check failed: unexpected options object class #{options.class}, expected Hash"
      end

      # auto-detect boolean parameters
      if options.has_key? :default
        if options[:default] == true || options[:default] == false
          options[:boolean] = true
        end
      end

      defaults = {
        multi: false,
        mandatory: false,
        default_param: false
      }
      @options = defaults.merge(options)
    end

    def lookup(current_values = {})
      begin
        return [] unless lookup_block = options[:lookup]

        # the lookup block might want the previously collected params as input
        lookups = if lookup_block.arity > 0
          lookup_block.call(current_values)
        else
          lookup_block.call()
        end
      rescue => detail
        $logger.error "problem loading lookup values for #{name} : #{detail.message}"
      end
    end

    # some params do not want to prefilled from the context
    def wants_context
      !(
        options.has_key?(:use_context) &&
        options[:use_context] == false
       )
    end

    def to_json(options)
      {
        name: @name,
        options: @options
      }.to_json(options)
    end

  end

end
