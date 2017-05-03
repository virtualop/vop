require 'vop/shell/backend'
require 'vop/shell/formatter'

class VopShellBackend < Backend

  attr_reader :command_history
  attr_reader :last_table, :last_result

  def initialize(op, options = {})
    @op = op
    @options = options
    @local_context = {}
    @command_history = []
    @last_table = nil
    @last_result = nil

    reset_to_command_mode
  end

  def context
    @local_context
  end

  def reset_to_command_mode
    # this shell has two modes that determine the available tab completion proposals
    # command_mode
    #    we're waiting for the user to pick a command that should be executed
    # parameter mode
    #    the command to execute has already been selected, but the user needs to specify additional parameters
    # we'll start in the mode where no command has been selected yet
    @command_selected = nil

    # if the user selected a command already, we'll have to collect parameters for this command until
    # we've got all mandatory parameters so that we can execute the command
    @collected_values = Hash.new { |h,k| h[k] = [] }

    @missing_params = []

    @current_param = nil
  end

  def process_ctrl_c
    puts "\n"
    if @command_selected
      reset_to_command_mode
    else
      Kernel.exit
    end
  end

  def set_prompt(p)
    @prompt = p
  end

  def prompt
    @command_selected && @current_param ?
      "#{@command_selected.short_name}.#{@current_param[:name]} ? " :
      @prompt || '>> '
  end

  def show_banner
    s = @options[:banner]
    puts s if s
  end

  def complete(word)
    $logger.debug "completing #{word}"

    list = []

    parts = nil

    if @command_selected
      $logger.debug("asking for lookup values for command '#{@command_selected.name}' and param '#{@current_param[:name]}'")
      list = @command_selected.lookup(@current_param[:name], @collected_values)
    else
      begin
        (parts, command, param_values) = parse_command_string(word)

        if command
          $logger.debug "command selected (#{command.name}), fetching param lookups"

          # all lookup values for a default_param (if exists)
          if command.default_param
            list += command.lookup(command.default_param[:name], @collected_values)
            $logger.debug "added lookups for default param, list now #{list.length} elements"
          end

          # names of all params that have not been specified yet or are :multi
          command.params.each do |param|
            raise "sanity check: no name found for #{param.inspect}"
            if not param_values.keys.include? param[:name] || param[:multi]
              list << param[:name]
            end
          end

        else
          $logger.debug "no command selected yet, returning command list"
          list = @op.commands.keys
        end
      rescue => e
        $logger.debug "can't parse >>#{word}<< : #{e.message}"
        $logger.debug e.backtrace
      end
    end

    the_filter = parts ? parts.last : word
    if the_filter
      $logger.debug "filtering completion list (#{list.size} items) against : #{the_filter}"
      list.delete_if do |x|
        x.nil? ||
        x[0...the_filter.size] != the_filter
      end
    end

    prefix = ''
    if parts
      prefix = parts.length > 1 ? parts[0..-2].join(" ").strip : ''
    end
    if $logger.debug?
      more_text = list.length > 1 ? " (and #{list.length-1} more)" : ''
      $logger.debug "completion from >#{word}< to #{prefix} + #{list.first}#{more_text}"
    end
    list.map do |x|
      [prefix, x].join(' ').strip
    end
  end

  def parse_command_string(command_line, presets = {})
    parts = command_line.split.map { |x| x.chomp.strip }
    (command_name, *params) = parts
    command = @op.commands[command_name]

    param_values = Hash.new { |h,k| h[k] = [] }
    presets.each do |k,v|
      param_values[k] = [v]
    end
    if params
      params.each do |param|
        if param =~ /(.+?)=(.+)/ then
          # --> named param
          key = $1
          value = $2
        else
          # --> unnamed param
          value = param
          if command
            default_param = command.default_param
            if default_param != nil then
              key = default_param[:name]
              $logger.debug "collecting value '#{value}' for default param '#{default_param[:name]}'"
            else
              $logger.debug "ignoring param '#{value}' because there's no default param"
            end
          else
            # can't process an unnamed param unless we've got a command
          end
        end

        if key
          param_values[key] << value
        end
      end
    end
    [parts, command, param_values]
  end

  def process_input(command_line)
    $logger.debug "+++ process_input #{command_line} +++"
    if @command_selected
      # we're in parameter processing mode - so check which parameter
      # we've got now and switch modes if necessary

      # we might have been waiting for multiple param values - check if the user finished
      # adding values by entering an empty string as value
      if @current_param && (@current_param[:multi] and command_line == "") then
        @missing_params.shift
        execute_command_if_possible
      else
        # TODO check +command_line+ against lookups/general validity?
        @collected_values[@current_param[:name]] << command_line
        if @current_param[:multi] then
          $logger.debug "param '#{@current_param[:name]}' expects multiple values...deferring mode switching"
        else
          @missing_params.shift
          execute_command_if_possible
        end
      end
    else
      (unused, @command_selected, values) = parse_command_string(command_line, @local_context)

      if @command_selected
        values.each do |key, value_list|
          begin
            value_list.each do |value|
              @current_param = @command_selected.param(key)
              if @current_param
                @collected_values[@current_param[:name]] << value
              else
                # TODO handle extra params?
              end
            end
          rescue Exception => ex
            # TODO broken (error: undefined method `accepts_extra_params' for Vop::Command machines.select_machine:Vop::Command)
            if @command_selected && false && @command_selected.accepts_extra_params
              puts "collecting value for extra param : #{key} => #{value}"
              @collected_values["extra_params"] = {} unless @collected_values.has_key?("extra_params")
              @collected_values["extra_params"][key] = Array.new if @collected_values["extra_params"][key] == nil
              @collected_values["extra_params"][key] << value
            else
              #puts "ignoring parameter value '#{value_list}' for param '#{key}' : " + ex.to_s
              raise ex
            end
          end
        end


        execute_command_if_possible
      end
    end
  end

  def execute_command_if_possible
    mandatory = @command_selected.mandatory_params
    @missing_params = mandatory.select { |p| ! @collected_values.include? p[:name] }

    if @missing_params.size > 0
      @current_param = @missing_params.first
    else
      execute_command
    end
  end

  def execute_command
    command = @command_selected

    begin
      extras = {
        # TODO needed for e.g. select_machine and show_context, but clutters up the stacks
        'shell' => self
      }
      request = Vop::Request.new(@op, command.short_name, @collected_values, extras)
      response = @op.execute_request(request)
      (result, context) = response.result, response.context

      if command.short_name == 'exit'
        $logger.info "exiting on user request"
        Kernel.exit(0)
      end

      if context
        if context['prompt']
          set_prompt context['prompt']
        end

        @local_context.merge! context
      end

      # @command_history << {
      #   command: request.command.name,
      #   params: request,
      #   response: response
      # } # (WiP)
      (display_type, result) = format_output(command, result)

      # remember the last displayed result for later "raw" output
      @last_result = result

      # remember the last shown table for "detail"ed output
      if display_type == :table
        $logger.debug "storing last table result : #{result.pretty_inspect}"
        @last_table = result
      end
    ensure
      reset_to_command_mode
    end
  end

  def inspect
    "<VopShellBackend>"
  end

end
