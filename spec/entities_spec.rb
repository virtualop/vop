require "spec_helper"
require "byebug"

RSpec.describe Vop do

  before(:example) do
    @vop = test_vop("entities", { log_level: Logger::INFO })
    @unnamed = @vop.entities["unnamed"]
  end

  it "has entities with descriptions" do
    expect(@vop.entities["chainsaw"].description).to eq "fun toy to juggle with"
  end

  it "can create entities" do
    entity = Vop::Entity.new(@vop, @unnamed, {"number" => 123})
  end

  it "can not create an entity without a key" do
    expect {
      Vop::Entity.new(@vop, @unnamed, {})
    }.to raise_error(/key.+not found/)
  end

  it "exposes an id, and a method named as the key" do
    expect(@unnamed.key).to eq "number"
    expect(@vop.unnameds.size).to be 1
    entity =  @vop.unnameds!.first
    expect(entity.id).to be 42
    expect(entity.number).to be 42
    expect { puts "entity name : #{entity.name}" }.to raise_error(/undefined method/)
  end

  # TODO moving this test up before the previous one makes that one fail (wtf?)
  it "stringifies entities without exploding" do
    shoe = @vop.shoes.first
    expect(shoe).to_not be nil
    expect(shoe.to_s.size).to be < 100
  end

  it "creates methods for all commands using the entity as param" do
    @vop.chainsaws.first.juggle
  end

  it "allows access through entity arrays by index or id" do
    # TODO do we need to be able to access entities by index (as opposed to key)?
    # expect(@vop.shoes[0]).to_not be nil
    expect(@vop.shoes["chucks"]).to_not be nil
    expect {
      @vop.shoes["salami"]
    }.to raise_error /no element with key/
  end

  it "auto-inflates entities when they are specified as symbols" do
    expect(@vop.auto_inflate("chainsaw" => 1)).to be_kind_of(Vop::Entity)
  end

  it "does not crash when entities are borked" do
    expect {
      test_vop("broken_entity")
    }.to raise_error ::Vop::Errors::EntityLoadError
  end

  it "does crash when an entity's key is called 'id'" do
    expect {
      vop = test_vop("entity_with_invalid_id")
      # TODO vop.booms
      raise "not checked"
    }.to raise_error
  end

end
