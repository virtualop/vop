require 'vop/entity'
require 'pp'

def define_entity(name, key, options)
  @op.core.state[:entities] << {
    name: name,
    key: key,
    options: options
  }
end

def entity(key = "name", options = {}, &block)
  command_name = @command.short_name

  # register the entity with the vop
  define_entity(command_name, key, options)

  # if an entity doesn't define a block, by default
  # it just passes through all contributions
  list_block = block || lambda do |params|
    @op.collect_contributions('name' => command_name, 'raw_params' => params)
  end

  if options[:on]
    param! options[:on].to_sym
  end

  # the entity command gets a mandatory param automatically, using the
  # block defined by the entity as lookup
  param! key, :lookup => list_block

  # entities generally accept contributions...
  accept_contributions

  # ...and have a special run block that filters the correct row from
  # the lookup list and returns an entity populated from that row
  @command.block = lambda do |params|
    list = list_block.call(params)

    found = list.select { |x| x[key.to_sym] == params[key] }
    if found && found.size > 0
      Entity.new(@op, command_name, key, found.first)
    else
      raise "no such entity : #{params[key]} [#{command_name}]"
    end
  end
end
