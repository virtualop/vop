module Vop

  class Entities < Array

    def [](key)
      $logger.debug "accessing entity with key '#{key}'"
      found = select { |x| x.id == key }.first
      if found
        found
      else
        if key.to_i.to_s == key.to_s
          super(key.to_i)
        else
          raise "no element with key '#{key}'"
        end
      end
    end

  end

end
