require "spec_helper"
require "tempfile"

RSpec.describe Vop do

  before(:example) do
    $logger.info "before vop_spec"
    @vop = test_vop
  end

  it "has a version number" do
    $logger.info "vop_spec"
    expect(Vop::VERSION).not_to be nil
  end

  it "can be initialized" do
    expect(@vop.plugins).to_not be nil
  end

  it "does not return a wall of text when stringified" do
    expect(@vop.to_s.size).to be < 100
  end

  it "makes commands available as methods" do
    expect(@vop.commands).to_not be nil
    expect(@vop.list_plugins).to_not be nil
  end

  it "refuses to load invalid plugins" do
    expect {
      test_vop("invalid_plugin")
    }.to raise_error(::Vop::Errors::PluginLoadError)
  end

  it "refuses to load invalid commands" do
    begin
      test_vop("invalid_command")
    rescue ::Vop::Errors::CommandLoadError => detail
      expect(detail.message).to match /problem loading command foo.broken/
    end
  end

  it "only eats what it knows" do
    expect {
      @vop << Hash.new
    }.to raise_error(::Vop::Errors::LoadError)
  end

  it "applies plugin templates" do
    vop = test_vop("plugin_templates")

    expect(vop.plugin("std1").options).to include(:auto_load => true)
    expect(vop.plugin("ext1").options).to include(:auto_load => false)
  end

  it "overrides commands with the same name" do
    vop = test_vop("override")

    expect(vop.commands["do_something"]).to_not be nil
    expect(vop.do_something).to eq "foo"
  end

  it "ignores commands that should not be registered" do
    vop = test_vop("dont_register")

    expect(vop.commands["wont_see_me"]).to be nil
    expect { vop.wont_see_me }.to raise_error (NoMethodError)
  end

  it "does not break if a config file contains invalid syntax" do
    path_to_invalid_config = Pathname.new(File.join(File.dirname(__FILE__), "lib", "config", "broken")).realpath
    puts "working with invalid config in #{path_to_invalid_config}"
    vop = test_vop(nil, config_path: path_to_invalid_config)
  end

  it "can write config and read it again" do
    Dir.mktmpdir("vop_config_write_test_#{Time.now.to_i}") do |tmpdir|
      #tmp = Tempfile.new("vop_config_write_test_#{Time.now.to_i}")
      vop = test_vop(nil, config_path: tmpdir)

      meta = vop.plugin("meta")
      meta.config["just"] = "kidding"
      meta.write_config

      new_vop = test_vop(nil, config_path: tmpdir)
      new_meta = new_vop.plugin("meta")
      expect(meta.config["just"]).to eql "kidding"
    end
  end

  it "does not load invalid helpers" do
    expect {
      test_vop("invalid_helper")
    }.to raise_error /undefined local variable/
  end

  it "fails to load a plugin whose dependencies are not met" do
    expect {
      test_vop("unresolved")
    }.to raise_error /dependency not met/
  end

  it "detects circular dependencies" do
    expect {
      test_vop("circular")
    }.to raise_error /circular/
  end

  it "does not load invalid filters" do
    expect {
      test_vop("invalid_filter")
    }.to raise_error /problem loading filter/
  end

  it "allows filters to change command results" do
    vop = test_vop("bruteforce_filter")

    expect(vop.list_plugins).to eql 42
  end

  it "complains when unknown entities are specified as params" do
    expect {
      vop = test_vop("unknown_entity")
    }.to raise_error /entity.+not found/
  end

  it "provides lookups for entity params" do
    vop = test_vop("entity_lookups")
    command = vop.commands["use_thing"]
    entity_param = command.param("thing")
    expect(entity_param).to_not be nil
    lookup = entity_param.options[:lookup]
    expect(lookup).to_not be nil
    lookups = lookup.call
    expect(lookups).to_not be nil
    expect(lookups).to eql ["foo","bar"]
  end

  it "knows how to get the source for a command" do
    command = @vop.commands["source"]
    expect(command.source).to_not be nil
  end

  it "checks that CommandParams are only initialized with Hash options" do
    expect(Vop::CommandParam.new("foo", {})).to_not be nil
    expect {
      Vop::CommandParam.new("foo", [])
    }.to raise_error /sanity check failed/
  end

end
