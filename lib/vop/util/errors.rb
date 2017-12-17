module Vop

  module Errors

    class RunningInCircles < StandardError
    end

    class MissingPlugin < StandardError
    end

    # see http://www.virtuouscode.com/2013/12/25/exception-causes-in-ruby-2-1/
    class NestedError < StandardError

      def initialize(message, original = $!)
        super(message + " : " + original.message)
        set_backtrace(original.backtrace)
      end

    end

    class CommandLoadError < NestedError
    end

    class PluginLoadError < StandardError
    end

    class EntityLoadError < LoadError

    end

    class LoadError < StandardError

      attr_reader :message, :detail

      def initialize(message = nil, detail = nil)
        @message = message
        @detail = detail
        super(detail)
      end

    end

  end

end
