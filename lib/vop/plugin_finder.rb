module Vop
  class PluginFinder

    def initialize(op)
      @op = op
    end

    def scan(dirs)
      $logger.debug("scanning #{dirs} for plugins...")
      dirs = [ dirs ] unless dirs.is_a? Array

      plugins = []
      templates = []

      dirs.each do |dir|
        next unless File.exists? dir

        plugins += Dir.glob("#{dir}/**/*.plugin").map { |x| Pathname.new(File.dirname(x)).realpath.to_s }
        templates += Dir.glob("#{dir}/**/plugin.vop").map { |x| Pathname.new(x).realpath.to_s }
      end

      [plugins, templates]
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
