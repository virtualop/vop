require 'vop/command'

module Vop

  class CommandLoader

    def initialize(plugin)
      @plugin = plugin
      @op = plugin.op

      @commands = {}

      # we need to load both the general helpers of the plugin because they are
      # used inside commands as well as the helpers specific to the command_loader
      @plugin.inject_helpers(self)
      @plugin.inject_helpers(self, 'command_loader')
    end

    def new_command(name)
      @command = Command.new(@plugin, name)
      @commands[@command.name] = @command
      @command
    end

    def run(&block)
      @command.block = block
    end

    def read_sources(named_commands)
      # reads a hash of <command_name> => <source string>
      named_commands.each do |name, source|

        new_command(name)

        begin
          self.instance_eval(source[:code], source[:file_name])
        rescue => detail
          raise "problem loading plugin #{name} : #{detail.message}\n#{detail.backtrace.join("\n")}"
        end
      end

      @commands
    end

  end

end
