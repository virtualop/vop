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

      if next_link
        next_link.execute(request)
      else
        nil
      end
    end

  end

end
