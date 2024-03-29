require "readline"

module Vop

  class ShellInputReadline

    def initialize(completion_method)
      Readline.completion_append_character = ""
      Readline.completion_proc = completion_method
      Readline.completer_word_break_characters = "\t\n\"\\'\`@$><=;|&{(" # default, but without space
    end

    def read(prompt)
      Readline.readline(prompt, true)
    end

    def exit
      Kernel.exit
    end

  end

end
