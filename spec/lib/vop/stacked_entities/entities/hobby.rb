on :user

entity do |params, user|
  [].tap do |result|
    case user.name
    when "slartibartfast"
      result << { "name" => "Knitting" }
    when "ruebennase"
      result << { "name" => "Gardening" }
      result << { "name" => "Rock climbing" }
    end
  end
end
