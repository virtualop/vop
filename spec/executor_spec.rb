require "spec_helper"

RSpec.describe Vop do

  before(:example) do
    @vop = test_vop("executor_spec")
  end

  it "handles default params" do
    expect(@vop.hello("world")).to eql("hello world")
  end

  context "when there are multiple params, but only one that is mandatory" do
    it "uses the single mandatory param as default param" do
      expect(@vop.one_mandatory("beeblebrox")).to eql({"zaphod" => "beeblebrox"})
    end
  end

  it "selects the correct default param out of many" do
    expect(@vop.multiple_params("beeblebrox")).to eql({ "bar" => "beeblebrox" })
  end

  it "resolves named block params" do
    expect(@vop.named_block_params("foo" => "bar")).to eql("bar")
    expect(@vop.named_block_params(foo: "bar")).to eql("bar")
  end

  it "autoboxes for parameters that want multiple values" do
    expect(@vop.autoboxing(wants_multi: 42, no_multi: "beeblebrox")).to eql({wants_multi: [42], no_multi: "beeblebrox"})
    expect(@vop.autoboxing(no_multi: ["auto-unboxing"])).to eql({no_multi: "auto-unboxing"})
  end

  it "converts boolean values" do
    expect(@vop.boolean(really: "yes")).to eql({really: true, implicit: false})
  end

  it "detects boolean parameters from default values" do
    expect(@vop.commands["boolean"].param("implicit").options).to include({boolean: true})
    expect(@vop.boolean).to eql({implicit: false})
  end

  it "merges in extra parameter values" do
    extra_result = @vop.execute("hello", {}, {"what" => "yehova"})
    expect(extra_result).to eql("hello yehova")
  end

  it "makes the plugin available to run blocks" do
    expect(@vop.block_params).to eql(@vop.plugin("executor_spec"))
  end

  it "provides context that might be changed" do
    request = Vop::Request.new(@vop, "change_context", {}, {})
    response = @vop.execute_request(request)
    expect(response.context).to eql({"foo" => "bar"})
  end

  it "handles optional block params gracefully" do
    expect(@vop.optional_block_param).to be nil
  end

  it "does not accept unknown block params" do
    expect { @vop.unknown_block_param }.to raise_error /unknown block param/
  end

  it "can generate cache keys from requests" do
    request = Vop::Request.new(@vop, "list_commands", { plugin_filter: "meta" }, {})
    expect(request.cache_key).to_not be nil
  end

end
