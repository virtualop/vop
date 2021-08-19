require "spec_helper"
require "byebug"

RSpec.describe "stacked entities" do

  before(:example) do
    @vop = test_vop("stacked_entities", { log_level: Logger::DEBUG })
  end

  it "can access stacked/nested entities" do
    expect(@vop.users.first.name).to eq "slartibartfast"
    # <dutch mode>
    expect(@vop.users["slartibartfast"].hobbys!.first.name).to eq "Knitting"
    expect(@vop.users["ruebennase"].hobbys!.map(&:name)).to eq ["Gardening", "Rock climbing"]
  end

end
