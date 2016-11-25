# responsible for what should happen when the user interacts with the shell
# provides tab completion options and processes the user's input
class Backend

  # is called whenever the user submits a command (hitting enter)
  def process_input(command_line)
    raise "not implemented in abstract Backend!"
  end

  # is called whenever the user requests tab completion
  # should return an array of completion proposals
  def complete(word)
    raise "not implemented in abstract Backend!"
  end

  def prompt
    ">"
  end

  def process_ctrl_c

  end

  def show_banner

  end

end
