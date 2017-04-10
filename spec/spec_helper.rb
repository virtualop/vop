require 'simplecov'
SimpleCov.start

require 'fileutils'
require 'vop'

module SpecHelper

  TEST_SRC_PATH = "/tmp/vop_rspec_test"
  TEST_CONFIG = "/tmp/vop_rspec_test_config"

  def empty_dir(path)
    if File.exists? path
      FileUtils.rm_r path
    end
    FileUtils.mkdir_p path
  end

  def prepare
    empty_dir(TEST_CONFIG)
    empty_dir(TEST_SRC_PATH)

    @vop = Vop::Vop.new(
      search_path: [ TEST_SRC_PATH ],
      config_path: TEST_CONFIG,
      verbose: false
    )
  end

end
