require "readline"
require_relative "shell_formatter"
require_relative "shell_input"
require_relative "shell_input_readline"

module Vop

  class Shell

    attr_reader :context

    def initialize(op, input = nil)
      @op = op
      @context = {}

      @formatter = ShellFormatter.new

      # TODO for testing
      if input.nil?
        input = ShellInputReadline.new(method(:tab_completion))
      end
      @input = input

      trap('INT') {
        handle_interrupt
      }

      reset
    end

    def reset
      @command = nil
      @arguments = {}

      @prompt = if @context.has_key?("prompt")
        @context["prompt"]
      else
        ">> "
      end
    end

    def handle_interrupt
      if @command
        reset
        puts
        print @prompt
      else
        puts "\n"
        exit
      end
    end

    def mix_arguments_and_context
      result = @arguments
      @context.each do |k,v|
        param = @command.param(k)
        if param && param.wants_context
          result[k] = @context[k]
        end
      end
      result
    end

    def maybe_execute
      mandatory = @command.mandatory_params

      missing_mandatory_params = @command.mandatory_params.delete_if do |param|
        @arguments.keys.include?(param.name) ||
        (@context.keys.include?(param.name) && param.wants_context)
      end

      if missing_mandatory_params.size > 0
        $logger.debug "missing params : #{missing_mandatory_params.map(&:name)}"
      end

      if missing_mandatory_params.size > 0
        @missing_params = missing_mandatory_params
        @prompt = "#{@command.short_name}.#{@missing_params.first.name} ? "
      else
        begin
          request = Request.new(@op, @command.short_name, @arguments, @context)
          request.shell = self
          response = @op.execute_request(request)

          @context.merge! response.context

          display_type = @formatter.analyze(request, response)
          formatted = @formatter.format(request, response, display_type)
          puts formatted
        rescue => detail
          puts "[ERROR] #{detail.message}\n#{detail.backtrace.join("\n")}"
        end
        reset
      end
    end

    def accept_param(line)
      current_param = @missing_params.shift
      $logger.debug "value for param #{current_param.name} : #{line}"
      @arguments[current_param.name] = line

      maybe_execute
    end

    def parse_command_line(args)
      result = {}
      unless args.empty?
        args.each do |token|
          if token.include? "="
            (key, value) = token.split("=")
            result[key] = value
          else
            default_param = @command.default_param
            if default_param
              result[default_param.name] = args
            end
          end
        end
      end
      result
    end

    def parse_and_execute(command_line)
      (command, *args) = command_line.split

      if command
        $logger.debug "command : #{command}, args : #{args}"
        if command.start_with?('$')
          if command.start_with?('$vop')
            puts "executing #{command}"
            puts eval command
          else
            puts "unknown $-command #{command} - try '$vop' maybe?"
          end
        elsif command.start_with?('@')
          if command.start_with?('@op')
            puts "executing #{command}"
            puts eval command
          else
            puts "unknown @-command #{command} - try '@op' maybe?"
          end
        else
          if command.end_with?("??")
            help_command = command[0..-3]
            command = "source"
            args << "name=#{help_command}"
          elsif command.end_with?("?")
            help_command = command[0..-2]
            command = "help"
            args << "name=#{help_command}"
          end

          if command == "exit"
            @input.exit
          else
            known_commands = @op.commands.keys
            if known_commands.include? command
              @command = @op.commands[command]
              @arguments = parse_command_line(args)

              maybe_execute
            else
              puts "unknown command '#{command}'"
            end
          end
        end
      end

    end

    def tab_completion(s)
      lookups = []

      if @command
        current_param = @missing_params.first
        if current_param && current_param.options.has_key?(:lookup)
          begin
            lookup_block = current_param.options[:lookup]

            # the lookup block might want the previously collected params as input
            lookups = if lookup_block.arity > 0
              params_for_lookup = mix_arguments_and_context
              lookup_block.call(params_for_lookup)
            else
              lookup_block.call()
            end
          rescue => detail
            $logger.error "problem loading lookup values for #{current_param.name} : #{detail.message}"
          end
        end
      else
        lookups = @op.commands.keys.sort
      end

      lookups.grep /^#{Regexp.escape(s)}/
    end

    def do_it(command_line = nil)
      #Readline.completion_append_character = ""
      #Readline.completion_proc = method(:tab_completion)

      if command_line
        parse_and_execute(command_line)
      else
        while line = @input.read(@prompt)
        #while line = Readline.readline(@prompt, true)
          if @command
            # if a command has already been selected, we ask for missing params
            accept_param(line)
          else
            # otherwise input is treated as regular command line (command + args)
            parse_and_execute(line)
          end
        end
      end
    end

    def self.run(op = nil, command_line = nil)
      if op.nil?
        op = Vop.new
      end
      self.new(op).do_it(command_line)
    end

  end

end
