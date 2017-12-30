module Vop

  class ThingWithParams

    attr_reader :params

    def initialize
      @params = []
    end

    def param(name)
      @params.select { |x| x.name == name }.first
    end

  end

end
