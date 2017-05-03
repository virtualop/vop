require 'spec_helper'
require 'vop'
require 'vop/entity'
require 'pp'
require 'fileutils'

RSpec.describe Vop do

PERSON = <<EOT
entity('number') do |params|
  [
    { name: "Beeblebrox", first_name: "Zaphod", number: 42 },
    { name: "Bond", first_name: "James", number: 007 }
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
      "name" => "Chucks",
      "color" => "#5F021F"
    }
  ]
end

EOT

COMMAND_THAT_USES_ENTITY = <<'EOT'
param :thing

run do |params|
  thing = params["thing"]
  "walking with #{thing}"
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

  it "is only here for test coverage" do
    entity = Vop::Entity.new(@vop, "cake", "mascarpone", {foo: 'snafoo', 'string': 'keys'})
    expect(entity.inspect).to_not be_nil
    # TODO expect(entity["foo"]).to eql "snafoo"
    expect(entity.foo).to eql "snafoo"
    expect(entity.string).to eql "keys"
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

  it "automagically registers commands for an entity as methods" do
    setup_entity("thing", THING_THAT_SHOULD_WORK)
    entity_command = @vop.new_command("plugin" => "entity_test", "name" => "cool_thing", "content" => COOL_THING)
    command = @vop.new_command("plugin" => "entity_test", "name" => "walk", "content" => COMMAND_THAT_USES_ENTITY)
    entity = @vop.thing("Chucks")
    expect(entity).to_not be_nil
    expect(entity.walk).to_not be_nil
  end

end
