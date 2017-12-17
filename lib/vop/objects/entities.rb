module Vop

  class Entities < Array

    def [](key)
      # if key.is_a? Numeric
      #   super(key)
      # else
        $logger.debug "accessing entity with key '#{key}'"
        found = select { |x| x.id == key }.first
        if found
          found
        else
          raise "no element with key '#{key}'"
        end
      # end
    end

  end

end
