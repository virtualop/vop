require 'vop'
require 'vop/shell/vop_shell_backend'
require 'vop/shell/base_shell'

require 'docopt'
require 'pp'

module Vop

  class Shell

USAGE = <<DOCOPT
virtualop

Usage:
  vop [options]

Options:
  -h --help       show this help screen
  -v --verbose    enable debug output
  -e --execute=<command>  to run a command directly

DOCOPT

    attr_reader :options
    attr_reader :op

    def initialize(vop = nil, options = {})
      @op = vop || Vop.new
      @options = options

      backend = VopShellBackend.new(@op, :color_prompt => true)
      @base_shell = BaseShell.new(backend)
    end

    def execute(string)
      @base_shell.backend.process_input(string)
    end

    def run_cli
      @base_shell.run
    end

    def self.setup()
      options = Docopt::docopt(USAGE, {:help => true})

      vop = Vop.new(options)
      return Shell.new(vop, options)
    end

  end
end
