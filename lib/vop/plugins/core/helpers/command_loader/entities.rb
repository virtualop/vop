require 'vop/entity'
require 'pp'

# if an entity doesn't define a block, by default
# it just passes through all contributions
def default_entity_block(params)
  params['contributions']
end

def define_entity(name, key, options)
  @op.plugins['core'].state[:entities] << {
    name: name,
    key: key,
    options: options
  }
end

def entity(key, options = {}, &block)
  command_name = @command.short_name

  # the entity command gets a mandatory param automatically, using the
  # block defined by the entity as lookup
  # TODO make the default block work
  #list_block = block || default_entity_block
  list_block = block

  if options[:on]
    param! options[:on]
  end

  param! key, :lookup => lambda { |params|
    collected = @op.collect_contributions('name' => command_name, 'raw_params' => params)
    params_with_contributions = params.merge(:contributions => collected)
    the_list = list_block.call(params_with_contributions)
    the_list
  }

  define_entity(command_name, key, options)

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
      raise "no such entity : #{params[key]} [#{command_name}]"
    end
  end
end
