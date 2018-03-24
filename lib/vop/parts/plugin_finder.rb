require "pathname"

module Vop

  class PluginFinder

    attr_reader :plugins, :templates

    def initialize
      reset
    end

    def reset
      @plugins = []
      @templates = []
    end

    def find(paths)
      reset

      $logger.debug "scanning #{paths} for plugins..."
      paths = [ paths ] unless paths.is_a? Array

      if paths.size > 0
        paths.each do |path|
          begin
            next unless File.exists? path
          rescue => e
            if e.message =~ /Fixnum/
              $logger.warn "unexpected Fixnum path : #{path}"
            end
            raise e
          end


          @plugins += Dir.glob("#{path}/**/*.plugin").map { |x| Pathname.new(File.dirname(x)).realpath.to_s }
          @templates += Dir.glob("#{path}/**/plugin.vop").map { |x| Pathname.new(x).realpath.to_s }
        end
      end

      self
    end

  end

end
