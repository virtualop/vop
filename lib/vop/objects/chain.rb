module Vop

  class Chain

    attr_reader :links

    def initialize(op, links)
      @op = op
      @links = links
    end

    def next
      @links.shift
    end

    def execute(request)
      next_link = self.next
      response = nil
      response = next_link.execute(request) if next_link
      response
    end

  end

end
