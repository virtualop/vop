module Vop
  class PluginFinder

    def initialize(op)
      @op = op
    end

    def scan(dirs)
      $logger.debug("scanning #{dirs} for plugins...")
      dirs = [ dirs ] unless dirs.is_a? Array

      plugin_files = []
      template_files = []

      dirs.each do |dir|
        next unless File.exists? dir

        plugin_files += Dir.glob("#{dir}/**/*.plugin").map { |x| File.dirname(x) }
        template_files += Dir.glob("#{dir}/**/plugin.vop")
      end

      [plugin_files, template_files]
    end

    def inspect(plugin_path)
      
    end

  end
end
