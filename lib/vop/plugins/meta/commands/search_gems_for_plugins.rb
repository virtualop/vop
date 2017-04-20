require "rubygems"
require "find"
require "digest"

run do |params|
  candidates = Gem::Specification.select { |spec| /^vop-plugins/ =~ spec.name }

  # checksum = Digest::MD5.new
  # candidates.map do |candidate|
  #   checksum << [ candidate.name, candidate.version ].join(":")
  # end
  # puts "gemspec md5 : #{checksum.hexdigest}"

  search_path = @op.show_search_path
  result = []

  candidates.each do |candidate|
    puts "inspecting #{candidate}"

    gem_path = candidate.full_gem_path

    Find.find(gem_path) do |path|
      # ignore hidden directories
      if FileTest.directory?(path)
        if File.basename(path)[0] == ?.
          Find.prune
        else
          next
        end
      end

      if FileTest.file?(path)
        if File.basename(path).split('.').last == 'plugin'
          unless result.include? gem_path
            unless search_path.include? gem_path
              result << gem_path
            end
          end
        end
      end
    end
  end

  result
end
