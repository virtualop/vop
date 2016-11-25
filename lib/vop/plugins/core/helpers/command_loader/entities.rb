require 'vop/entity'
require 'pp'

# if an entity doesn't define a block, by default
# it just passes through all contributions
def default_entity_block(params)
  params['contributions']
end

def entity(key, options = {}, &block)

  command_name = @command.short_name

  # the entity command gets a mandatory param automatically, using the
  # block defined by the entity as lookup
  #list_block = block || default_entity_block
  list_block = block

  param! key, :lookup => lambda { |params|
    collected = @op.collect_contributions('name' => command_name, 'raw_params' => params)
    params_with_contributions = params.merge(:contributions => collected)
    the_list = list_block.call(params_with_contributions)
    the_list.map { |x| x[key.to_sym] }
  }

  @op.plugins['core'].state[:entities] ||= []
  @op.plugins['core'].state[:entities] << command_name

  # entities generally accept contributions...
  accept_contributions

  # ...and they have a special run block that filters the correct row from
  # the lookup list and returns an entity populated from that row
  @command.block = lambda do |params|
    collected = @op.collect_contributions('name' => command_name, 'raw_params' => params)
    params_with_contributions = params.merge(:contributions => collected)
    list = list_block.call(params_with_contributions)

    found = list.select { |x| x[key.to_sym] == params[key] }
    if found && found.size > 0
      Entity.new(@op, command_name, key, found.first)
    else
      raise "no such entity : #{params[key]}"
    end
  end
end
