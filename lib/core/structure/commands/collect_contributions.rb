description "This is called by a command accepting contributions - it calls all contributors and merges the result"

param! "command_name", default_param: true
param "raw_params", default: {}

run do |command_name, raw_params|
  contributors = @op.list_contributors(command_name: command_name)

  target_name = command_name.split(".").last
  target = @op.commands[target_name]

  if target.nil?
    raise "contribution target #{target_name} not found"
  end

  display_type = target.show_options[:display_type] || :table

  result = case display_type
  when :table
    []
  when :hash
    {}
  else
    raise "contributions not implemented for display_type #{display_type}"
  end

  contributors.each do |contributor_name|
    short_name = contributor_name.split(".").last
    contributor = @op.commands[short_name]

    contribution = @op.execute(short_name, raw_params)

    if contribution.nil?
      $logger.debug "command #{short_name} contributes a nil value"
    else
      case display_type
      when :table
        result += contribution
      when :hash
        result.merge! contribution
      end
    end
  end

  result
end
