require "rubygems"
require "find"
require "digest"

contribute to: "search_path" do |params|
  #candidates = Gem::Specification.select { |spec| /^vop-plugins/ =~ spec.name }
  gem_list = `gem list`.split("\n")  
  candidates = gem_list.select { |x| x =~ /vop-plugins/ }

  # checksum = Digest::MD5.new
  # candidates.map do |candidate|
  #   checksum << [ candidate.name, candidate.version ].join(":")
  # end
  # puts "gemspec md5 : #{checksum.hexdigest}"

  result = []

  candidates.each do |candidate|
    $logger.debug "inspecting #{candidate}"

    matched = /(.+?)\s+\([\d\.]+\)/.match(candidate)
    unless matched
      $logger.warn("unexpected line format : #{candidate}")
      next
    end

    name = matched.captures.first
    version = matched.captures.last

    contents = `gem contents #{name}`.split("\n")

    plugin_files = contents.grep /\.plugin$/
    result += plugin_files.map do |file_name|
      file_name.split("/")[0..-2].join("/")
    end



  #   gem_path = candidate.full_gem_path
  #
  #   Find.find(gem_path) do |path|
  #     # ignore hidden directories
  #     if FileTest.directory?(path)
  #       if File.basename(path)[0] == ?.
  #         Find.prune
  #       else
  #         next
  #       end
  #     end
  #
  #     if FileTest.file?(path)
  #       if File.basename(path).split('.').last == 'plugin'
  #         unless result.include? gem_path
  #           result << gem_path
  #         end
  #       end
  #     end
  #   end
  end

  #search_path = @op.show_search_path
  #result.delete_if { |x| search_path.include? x }

  # result.map do |x|
  #   { "path" => x }
  # end
  result
end
