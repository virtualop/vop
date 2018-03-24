module Vop

  class TestableShellInput

    attr_accessor :answers
    attr_reader :exit

    def initialize
      @answers = []
      @exit = false
    end

    def read(prompt)
      answer = @answers.shift
      if answer.nil?
        raise "no more pre-defined answers (asked for '#{prompt}')"
      end
      answer
    end

    def exit
      @exit = true
    end

  end

end
