require "simplecov"
SimpleCov.start

require "fileutils"
require "vop"

module SpecHelper

  TEST_TMP_PATH = "/tmp/vop_rspec"
  TEST_SRC_PATH     = "#{TEST_TMP_PATH}/src"
  TEST_SRC_PATH_ALT = "#{TEST_TMP_PATH}/src2"

  TEST_CONFIG = "#{TEST_TMP_PATH}/config"

  def empty_dir(path)
    if File.exists? path
      FileUtils.rm_r path
    end
    FileUtils.mkdir_p path
  end

  def prepare
    empty_dir(TEST_TMP_PATH)
    [ TEST_SRC_PATH, TEST_SRC_PATH_ALT, TEST_CONFIG ].each do |path|
      FileUtils.mkdir_p path
    end

    @vop = Vop::Vop.new(
      "search_path" => [ TEST_SRC_PATH ],
      :config_path => TEST_CONFIG,
      :verbose => false
    )
  end

end
