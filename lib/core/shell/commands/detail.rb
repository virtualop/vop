param "index"

show display_type: :raw

run do |shell, index|
  last_result = shell.last_response&.result

  result = if last_result
    if last_result.is_a?(Array) && index
      last_result[index.to_i]
    else
      last_result
    end
  end

  if result.is_a? ::Vop::Entity
    result.data
  else
    result
  end
end
