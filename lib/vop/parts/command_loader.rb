require_relative "../syntax/command_syntax"
require_relative "../objects/command"

module Vop

  class CommandLoader

    def initialize(plugin)
      @plugin = plugin
      @op = plugin.op

      @commands = []

      @plugin.inject_helpers(self)

      extend CommandSyntax
    end

    def new_command(name)
      @command = Command.new(@plugin, name)
      @commands << @command
      @command
    end

    def read_sources(named_commands)
      # reads a hash of <command_name> => <source string>
      named_commands.each do |name, source|

        new_command(name)

        begin
          self.instance_eval(source[:code], source[:file_name])
        rescue Exception
          raise Errors::CommandLoadError.new("problem loading command #{name}")
        end
      end

      @commands
    end

  end

end
