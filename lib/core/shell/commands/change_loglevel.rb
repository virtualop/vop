param! "level"

run do |level|
  new_level = Logger.const_get(level.upcase)
  $logger.level = new_level
end
