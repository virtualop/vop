param! "name"
param "except", :multi => true
param! "raw_params"

run do |name, raw_params, params|
  target = @op.commands[params["name"].split(".").last]
  $logger.debug "collecting contributions for target : #{target.name}"

  Thread.current[:contributing] ||= Hash.new { |h,k| h[k] = 0 }
  Thread.current[:contributing][target] += 1
  $logger.debug "  (contribution counter currently #{Thread.current[:contributing][target]})"

  begin
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

        $logger.debug "thinking about calling #{contributor} for contribution to #{name}"

        if Thread.current[:contributing][target] > 1
          if Thread.current[:contribution_result]
            unless Thread.current[:contribution_result][target].nil?
              $logger.debug "using previous result to avoid contribution loop (#{target})"
              result = Thread.current[:contribution_result][target]
            else
              $logger.warn "seem to be inside a contribution loop (#{target.name}), but do not have a previous result to work with."
            end
          end
        else
          short_name = contributor.to_s.split(".").last

          contribution = @op.send(short_name.to_sym, raw_params)
          case display_type
          when :table
            result += contribution
          when :hash
            result.merge! contribution
          end
          $logger.debug "new result : #{result.pretty_inspect}"
          Thread.current[:contribution_result] ||= {}
          Thread.current[:contribution_result][target] = result
        end
      end
    end
  ensure
    Thread.current[:contributing][target] -= 1
  end

  result
end
