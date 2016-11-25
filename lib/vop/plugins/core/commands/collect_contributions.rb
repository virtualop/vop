param! 'name'
param 'except', :multi => true
param! 'raw_params'

run do |name, raw_params, params|
  result = []

  registry = @op.plugins['core'].state[:contributions]
  if registry.has_key? name
    contributors = registry[name]
    contributors.each do |contributor|
      except = params['except'] || []
      if except.include? contributor
        puts "skipping contributor #{contributor} because of except"
        next
      end

      $logger.debug "calling #{contributor} for contribution to #{name}"
      #puts caller[0..10]
      if caller.grep(/eval.*block in entity/).size > 1
        $logger.debug "skipping contribution from #{contributor} because of loop"
      else
        short_name = contributor.to_s.split('.').last
        result += @op.send(short_name.to_sym, raw_params)
      end
    end
  end

  result
end
