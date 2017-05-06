require 'vop/entity'
require 'pp'

def define_entity(name, key, options, list_block)
  @op.plugins['commands'].state[:entities] << {
    name: name,
    key: key,
    options: options,
    list_block: list_block
  }
end

def entity(key = 'name', options = {}, &block)
  command_name = @command.short_name

  # if an entity doesn't define a block, by default
  # it just passes through all contributions
  list_block = block || lambda do |params|
    @op.collect_contributions('name' => command_name, 'raw_params' => params)
  end

  # register the entity with the vop
  # TODO should we also merge other parts of the command (e.g. description?)
  define_entity(command_name, key, options.merge(@command.show_options), list_block)

  # the entity command gets a mandatory param automatically, using the
  # block defined by the entity as lookup
  lookup = lambda do |params|
    $logger.debug "looking up (key #{key})"

    begin
      result = list_block.call(params)
      if result.is_a?(Array) && result.first.is_a?(Hash)
        result.map! do |row|
          row[key]
        end
      end
    rescue => e
      $logger.warn "could not lookup #{key} : #{e.message}"
    end

    $logger.debug "looked up: #{result.pretty_inspect}"
    result
  end
  param! key, lookup: lookup

  # when an entity is stacked on another entity, the "parent" entity needs to
  # be specified as param to identify a "child" entity (think services on machines)
  if options[:on]
    param! options[:on].to_sym
  end

  # ...and have a special run block that filters the correct row from
  # the lookup list and returns an entity populated from that row
  @command.block = lambda do |params|
    list = list_block.call(params)

    $logger.debug "searching entity by #{key} '#{params[key]}'"
    found = list.select { |x| x[key] == params[key] }
    unless found && found.size > 0
      raise "no such entity : #{params[key]} [#{command_name}]"
    end

    $logger.debug "found entity #{command_name} (#{key}) : #{found.first.pretty_inspect}"

    Entity.new(@op, command_name, key, found.first)
  end
end
