param! "name"
param "except", :multi => true
param! "raw_params"

run do |name, raw_params, params|
  target = @op.commands[params["name"].split(".").last]
  $logger.debug "target : #{target.pretty_inspect}"

  display_type = target.show_options[:display_type] || :table

  result = case display_type
  when :table
    []
  when :hash
    {}
  else
    raise "contributions not implemented for display_type #{display_type}"
  end
  $logger.debug "initialized result : #{result.pretty_inspect}"

  registry = @op.plugins["contributions"].state[:contributions]
  if registry.has_key? name
    contributors = registry[name]
    contributors.each do |contributor|
      except = params["except"] || []
      if except.include? contributor
        puts "skipping contributor #{contributor} because of except"
        next
      end

      $logger.debug "calling #{contributor} for contribution to #{name}"
      #puts caller[0..10]
      if caller.grep(/eval.*block in entity/).size > 2
        $logger.debug "skipping contribution from #{contributor} because of loop"
      else
        $logger.debug "raw params: " + raw_params.inspect
        short_name = contributor.to_s.split(".").last

        contribution = @op.send(short_name.to_sym, raw_params)
        case display_type
        when :table
          result += contribution
        when :hash
          result.merge! contribution
        end
        $logger.debug "new result : #{result.pretty_inspect}"
      end
    end
  end

  result
end
