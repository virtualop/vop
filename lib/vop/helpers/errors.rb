module Vop

  module Errors

    class RunningInCircles < StandardError
    end

    class MissingPlugin < StandardError
    end

    class NoSuchCommand < StandardError
    end

    class SyntaxError < StandardError
    end

  end

end
