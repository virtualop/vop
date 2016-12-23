require 'vop'
require 'pp'
require 'fileutils'
require 'spec_helper'

RSpec.describe Vop do

PERSON = <<EOT
entity('number') do |params|
  [
    {name: "Beeblebrox", first_name: "Zaphod", number: 42},
    {name: "Bond", first_name: "James", number: 007}
  ]
end

EOT

THING_THAT_SHOULD_WORK = <<EOT
entity('name')

EOT

COOL_THING = <<EOT
contribute to: 'thing' do |params|
  [
    {
      name: "Chucks",
      color: "#5F021F"
    }
  ]
end

EOT

  include SpecHelper
  before(:example) do
    prepare
  end

  def setup_entity(name, content)
    new_plugin = @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "entity_test")
    entity_command = @vop.new_command("plugin" => "entity_test", "name" => name, "content" => content)
    expect(@vop.list_entities).to include(name)
  end

  it "allows to define entities" do
    setup_entity("person", PERSON)
    expect(@vop.list_people).to_not be_nil
  end

  it "allows entities without run block" do
    setup_entity("thing", THING_THAT_SHOULD_WORK)
    entity_command = @vop.new_command("plugin" => "entity_test", "name" => "cool_thing", "content" => COOL_THING)
    expect(@vop.list_things).to_not be_nil
    expect(@vop.cool_thing("Chucks")).to_not be_nil
  end

end
