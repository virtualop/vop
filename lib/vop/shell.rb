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

DOCOPT

    def initialize(vop = nil, options = {})
      @op = vop || Vop.new
      @options = options
    end

    def run_cli
      backend = VopShellBackend.new(@op, :color_prompt => true)
      BaseShell.new(backend).run
    end

    def self.setup()
      options = Docopt::docopt(USAGE, {:help => true})
      vop = Vop.new(options)
      return Shell.new(vop)
    end

  end
end
