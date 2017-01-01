require 'fileutils'
require 'vop'

module SpecHelper

  TEST_SRC_PATH = "/tmp/vop_rspec_test"
  TEST_CONFIG = "/tmp/vop_rspec_test_config"

  def prepare
    FileUtils.mkdir_p TEST_CONFIG
    if File.exists? TEST_SRC_PATH
      FileUtils.rm_r TEST_SRC_PATH
    end
    Dir.mkdir TEST_SRC_PATH
    @vop = Vop::Vop.new(
      search_path: TEST_SRC_PATH,
      config_path: TEST_CONFIG,
      verbose: false
    )
  end

end
