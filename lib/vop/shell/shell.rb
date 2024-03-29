require_relative "shell_formatter"
require_relative "shell_input"
require_relative "shell_input_readline"

module Vop

  class Shell

    attr_reader :context
    attr_reader :last_response

    def initialize(op, input = nil)
      @op = op
      @context = {}

      @formatter = ShellFormatter.new

      # override for testing
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

    def mix_arguments_and_context(command = nil, arguments = nil)
      result = arguments || @arguments
      @context.each do |k,v|
        cmd = command || @command
        if cmd
          param = (cmd).param(k)
          if param && param.wants_context
            result[k] = @context[k]
          end
        end
      end
      result
    end

    def missing_mandatory_params(command = @command, arguments = @arguments)
      command.mandatory_params.delete_if do |param|
        arguments.keys.include?(param.name) ||
        (@context.keys.include?(param.name) && param.wants_context)
      end
    end

    def maybe_execute
      if missing_mandatory_params.size > 0
        @missing_params = missing_mandatory_params
        @prompt = "#{@command.short_name}.#{@missing_params.first.name} ? "
      else
        begin
          request = @op.prepare_request(@command.short_name, @arguments, @context, @command.short_name)
          request.shell = self
          response = @op.execute_request(request)

          # log the last response for the "detail" command
          unless @command.short_name == "detail"
            @last_response = response
          end

          # mix context changes from the response into the local context
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
      unless line.nil?
        current_param = @missing_params.shift
        $logger.debug "value for param #{current_param.name} : #{line}"
        @arguments[current_param.name] = line

        maybe_execute
      end
    end

    def is_special?(command)
      command.start_with?('$') || command.start_with?('@') || command.end_with?('?')
    end

    def handle_special(command)
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
      end
    end

    def parse(command_line)
      (command, *args) = command_line.split

      arguments = {}
      if command
        $logger.debug "command : #{command}, args : #{args}"

        if command.end_with?("??")
          target_command = command[0..-3]
          command = "source"
          arguments["name"] = target_command
        elsif command.end_with?("?")
          target_command = command[0..-2]
          command = "help"
          arguments["name"] = target_command
        end

        known_commands = @op.commands.keys
        if known_commands.include? command
          cmd = @op.commands[command]

          unless args.empty? || is_special?(command)
            args.each do |token|
              if token.include? "="
                (key, value) = token.split("=")
                arguments[key] = value
              else
                default_param = cmd.default_param(mix_arguments_and_context)
                if default_param
                  arguments[default_param.name] = args
                end
              end
            end
          end
          [command, cmd, arguments]
        else
          [command, nil, arguments]
        end
      end
    end

    def parse_and_execute(command_line)
      command, cmd, arguments = parse(command_line)

      if command
        $logger.debug "command : #{command}, args : #{arguments}"
        if is_special?(command)
          handle_special(command_line)
        else
          if command == "exit"
            @input.exit
          else
            if cmd
              @command = cmd
              @arguments = arguments
              maybe_execute
            else
              puts "unknown command '#{command}'"
            end
          end
        end
      end
    end

    def complete_for_command(s)
      current_param = @missing_params.first
      if current_param && current_param.options.has_key?(:lookup)
        begin
          lookup_block = current_param.options[:lookup]

          # the lookup block might want the previously collected params as input
          lookups = if lookup_block&.arity > 0
            params_for_lookup = mix_arguments_and_context
            lookup_block.call(params_for_lookup)
          else
            lookup_block.call()
          end
          lookups.grep /^#{Regexp.escape(s)}/
        rescue => detail
          $logger.error "problem loading lookup values for #{current_param.name} : #{detail.message}"
        end
      end
    end

    def complete_command_line(s)
      potential_command, potential_cmd, potential_args = parse(s)
      #$logger.debug "? >>#{potential_cmd}<< (#{potential_args}) [#{Readline.line_buffer}]"
      if potential_cmd
        default_param = potential_cmd.default_param
        if default_param
          lookups = default_param.lookup(mix_arguments_and_context)
          lookups
            .grep(/^#{Regexp.escape(s.split.last)}/)
            .map do |lookup|
              "#{potential_command} #{lookup}"
            end
        end
      else
        lookups = @op.commands.keys.sort.grep /^#{Regexp.escape(s)}/
      end

    end

    def tab_completion(s)
      if @command
        complete_for_command(s)
      else
        complete_command_line(s)
      end
    end

    def do_it(command_line = nil)
      if command_line && command_line != ""
        parse_and_execute(command_line)
      else
        while line = @input.read(@prompt)
          if @command
            # if a command has already been selected, ask for missing params
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
        op = Vop.new(origin: "shell:#{Process.pid}@#{`hostname`.strip}")
      end
      self.new(op).do_it(command_line)
    end

  end

end
