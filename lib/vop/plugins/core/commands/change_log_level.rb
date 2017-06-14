param! "new_level", lookup: lambda { |_| %w|debug info warn error| }

run do |new_level|
  $logger.level = Logger.const_get(new_level.upcase)
end
