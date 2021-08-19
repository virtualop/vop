require "rubygems"
require "find"
require "digest"

contribute to: "not_this_search_path" do |params|
  gem_list = `gem list`.split("\n")
  candidates = gem_list.select { |x| x =~ /vop-\w+/ }

  # TODO cache which gems have already been inspected
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
  end
  result
end
