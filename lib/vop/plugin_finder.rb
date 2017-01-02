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
      plugin_name = plugin_path.split("/").last
      file_name = File.join(plugin_path, "#{plugin_name}.plugin")

      result = {
        source_dirs: {}
      }

      Dir.foreach(plugin_path) do |file_name|
        next if file_name[0] == "."

        full_name = File.join(plugin_path, file_name)

        # consider all directories containing "*.*rb" files as source
        # (and the files directory, whatever is inside)
        if File.directory?(full_name)
          ruby_files = Dir.glob("#{full_name}/*.*rb")
          known_suspects = %w|files|
          if ruby_files.size > 0 || known_suspects.include?(file_name)
            result[:source_dirs][file_name] = ruby_files
          end
        end
      end

      result
    end

  end
end
