module Vop

  class TestableShellInput

    attr_accessor :answers
    attr_reader :exit, :prompt
    attr_accessor :fail_if_out_of_answers

    def initialize
      @answers = []
      @exit = false
      @prompt = nil
      @fail_if_out_of_answers = true
    end

    def read(prompt)
      @prompt = prompt
      answer = @answers.shift
      if answer.nil? && @fail_if_out_of_answers
        unless @exit
          raise "no more pre-defined answers (asked for '#{prompt}')"
        end
      end
      answer
    end

    def exit
      @exit = true
    end

  end

end
