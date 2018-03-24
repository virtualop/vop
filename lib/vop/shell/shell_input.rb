module Vop

  class ShellInput

    def initialize(completion_method)
    end

    def read(prompt)
      raise "read() not implemented in abstract base class ShellInput!"
    end

  end

end
