module SpecHelper

  TEST_SRC_PATH = "/tmp/vop_rspec_test"

  def prepare
    if File.exists? TEST_SRC_PATH
      FileUtils.rm_r TEST_SRC_PATH
    end
    Dir.mkdir TEST_SRC_PATH
    @vop = Vop::Vop.new
    @vop.add_search_path TEST_SRC_PATH
  end

end
