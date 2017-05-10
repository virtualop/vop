require "spec_helper"
require "vop"

RSpec.describe Vop::Command do

  include SpecHelper
  before(:example) do
    prepare

    @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "command_spec")
  end

  it "accepts named params" do
    expect(@vop.source("name" => "source")).to_not be_nil
  end

  it "accepts default params" do
    expect(@vop.source("source")).to_not be_nil
  end

  it "complains about missing mandatory params" do
    expect { @vop.source() }.to raise_error(RuntimeError)
  end

  it "shows mandatory params" do
    source_cmd = @vop.commands["source"]
    expect(source_cmd.mandatory_params.size).to be == 1
  end

  it "returns lookups" do
    source_cmd = @vop.commands["source"]
    expect(source_cmd.lookup("name", {}).size).to be > 0
  end

FOO_COMMAND = <<'EOC'
param "foo"

run do |params|
  params["foo"]
end
EOC

  it "does not crash when there are no lookups" do
    @vop.new_command("name" => "the_command", "plugin" => "command_spec", "content" => FOO_COMMAND)
    the_command = @vop.commands["the_command"]
    attempt = the_command.lookup("foo", {}).size
    expect(attempt).to_not be nil
    expect(attempt).to be 0
  end

  it "does default params to nil" do
    @vop.new_command("name" => "the_command", "plugin" => "command_spec", "content" => FOO_COMMAND)
    foo_default = @vop.the_command()
    expect(foo_default).to be nil
  end

AUTOBOX_COMMAND = <<'EOC'
param "foo", multi: true

run do |foo|
  foo.to_json()
end
EOC

  it "auto-boxes params that accept multiple values" do
    @vop.new_command("plugin" => "command_spec", "name" => "autobox", "content" => AUTOBOX_COMMAND)
    json = @vop.autobox("foo" => "zaphod")
    data = JSON.parse(json)
    expect(data).to eql ["zaphod"]
  end

AUTOUNBOX_COMMAND = <<'EOC'
param "foo", multi: false

run do |foo|
  foo
end

EOC

  it "auto-unboxes params" do
    @vop.new_command("plugin" => "command_spec", "name" => "autounbox", "content" => AUTOUNBOX_COMMAND)
    data = @vop.autounbox("foo" => ["zaphod"])
    expect(data).to eql "zaphod"

  end

  it "auto-boxes default params" do
    @vop.new_command("plugin" => "command_spec", "name" => "autobox", "content" => AUTOBOX_COMMAND)
    json = @vop.autobox("zaphod")
    data = JSON.parse(json)
    expect(data).to eql ["zaphod"]
  end

BOOLEAN_COMMAND = <<'EOC'
param "really", default: false

run do |really|
  really ? 42 : 0
end
EOC

  it "converts booleans from string" do
    @vop.new_command("plugin" => "command_spec", "name" => "do_it", "content" => BOOLEAN_COMMAND)
    expect(@vop.do_it).to eql 0
    expect(@vop.do_it("really" => true)).to eql 42
    expect(@vop.do_it("really" => "true")).to eql 42
    expect(@vop.do_it(true)).to eql 42
    expect(@vop.do_it("Yes")).to eql 42
    expect(@vop.do_it("on")).to eql 42

    expect(@vop.do_it("no")).to eql 0
    expect(@vop.do_it("off")).to eql 0
    expect(@vop.do_it("false")).to eql 0
    expect(@vop.do_it(false)).to eql 0
  end

USE_PATH_ENTITY = <<'EOC'
param! :path

run do |path|
  path.is_a? Entity
end
EOC

  it "inflates entity parameters" do
    first_path = @vop.list_paths.first
    unless first_path.nil?
      @vop.new_command("plugin" => "command_spec", "name" => "use_path_entity", "content" => USE_PATH_ENTITY)
      path = first_path["path"]
      expect(@vop.use_path_entity(path)).to be true
    end
  end

end
