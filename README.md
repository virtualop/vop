The vop is a scripting framework.

It organizes ruby scripts as *commands* living in *plugins*, defines and manages *services*, and can be accessed from the command line or a web interface.

## Status : Alpha

This is work in progress. Do not assume everything you read to be totally accurate, stable or final.

# Installation

## as a gem:

  $ gem install vop

# Usage

Call `vop` to start the shell.

# Syntax

## Plugins

Minimally, a plugin is a folder containing a file called "&lt;name&gt;.plugin". An empty file will do.

optional:
```
description "really nice plugin, this one"

auto_load false    # default is true
```

dependencies:
```
depends_on :other_plugin
depends_on [ :many, :other, :plugins ]
```

hooks:
```
hook :before_execute do |payload|
  request = payload[:request]
end

hook :after_execute do |payload|
  request = payload[:request]
  response = payload[:response]
end
```

config:
```
config_param "foo" [, { options }]
config_param! "snafoo" [, { options }]
```

accessing plugin config inside command:
```
run do |plugin|
  plugin.config["foo"]
end
```

## Commands

...are loaded from the `commands` folder in a plugin.

Minimally, a command needs only a run block:
```
run { 42 }
```

Also, you can use any of these:
```
description "Roses are red."

read_only   # => cacheable
```

A command can define parameters
```
param "snafoo"    # optional
param! "snafoo"   # mandatory
param! :snafoo    # mandatory entity
```
param syntax:
```
param[!] ( "name" | :entity ) [, {option: value}]
```
full example:
```
param! "foo",
  description: "it's the foo.",
  multi: true,
  default: [ "snafoo", "footoristic", "foofoo", "foolosophy" ],
  default_param: true,
  lookup: lambda { |params| %w|string array| }  
```

to access param values, use the `params` hash or named block variables:
```
param "foo"
param "not_really"

run do |params, not_really|
  puts params["foo"] unless not_really
end
```

entity parameters are resolved from the specified key to the entity:
```
param :machine

run do |machine|
  puts machine.name
end
```

There is special handling in place for block parameters.

Declare one with
```
block_param
```
or
```
block_param!
```
and a block can be passed to the command like this:
```
@op.foo do
  # whatever you need to do
end
```
From inside your command, you can access the block through the parameter called `block`.

contribute:
```
contribute to: "other_command" do |params|
end
```

collect contributions:
```
@op.collect_contributions(
  command_name: "other_command",
  raw_params: {}
)
```


show (display options for shell output):
```
show columns: ["name", "number"]
show sort: false
show display_type: :raw
```
`display_type` can be any of:
```
:data
:raw
:table
:list
:hash
```
(see [`shell/formatter.rb`](https://github.com/virtualop/vop/blob/master/lib/vop/parts/shell_formatter.rb))

## Services

Plugin folder: `services`

install one or multiple OS packages:
```
deploy package: <foo>
deploy package: [ <foo>, <bar>, <baz> ]
```

install a virtualop service:
```
deploy service: "plugin.service"
```

deploy configuration from a template:
```
deploy template: "foo.conf.erb",
  to: "/etc/foo/conf.d/foo.conf"
```

install (configuration for) a debian package repository:
```
deploy repository: {
  alias: "funny-name",
  url: "https://package.repository.somewhere.xxx",
  dist: "stable/",
  key: "https://download.somewhere.xxx/the.gpg.key"
}
```

run arbitrary vop or ruby code during deployment of a service:
```
deploy do |machine|


end
```

## Entities

Each entity is a file in the `/entities` subfolder of a plugin.

A minimal entity is an array of hashes, each with a unique "name" attribute:

```
entity do
  [
    {
      "name" => "foo"
    }
  ]
end
```

Instead of "name", a differing key attribute can be specified with `key`:
```
key "path"

entity do
  [
    {
      "path" => "/bin/false"
    }
  ]
end
```

The `on` keyword allows to stack entities onto another, e.g. the `log` entity living on a machine:
```
key "path"

on :machine

entity do |machine|
  # ...
end
```
A stacked entity (or rather, the list command generated from the entity) automatically has a parameter for the entity it is stacked on - in the log example:
```
>> logs?

logs

syntax:
  logs <machine>

parameters:
  machine
```

# Development

## required dependencies

* (to checkout sources: git)
* ruby + headers (e.g. packages `ruby` and `ruby-dev` on Ubuntu)
* bundler (`gem install bundler`)

## setup
After checking out the repo, run `bin/setup` to install (gem) dependencies.
Then, run `bundle exec rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To start the vop from the checked out sources, set the environment variable `VOP_DEV_MODE` to any value, e.g. like this:
```
export VOP_DEV_MODE=1
```
and then run `exe/vop`.

### packaging
To install the vop from source as a gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/virtualop/vop.
