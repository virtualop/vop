

The vop is a systems automation scripting framework.

It organizes (ruby) scripts into commands living in plugins, defines services that can be installed and managed, and comes with a shell and a web interface.

# Status: WIP

This is work in progress. Do not assume everything you read to be totally accurate and/or stable.

# Installation

## as a gem:

    $ gem install vop

# Usage

Call `vop` to start the shell.

Use the tab key for completion, type "help" for more info, `list_plugins` and `list_commands` for an overview.

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

## Commands

...are loaded from the `commands` folder in a plugin.

minimal:
```
run { 42 }
```

optional:
```
description "Roses are red."

read_only   # => cacheable
```

defining param(eter)s:
```
param "snafoo"    # optional
param! "snafoo"   # mandatory
param! :snafoo    # entity
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

contribute:
```
contribute to: "other_command" do |params|
end
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

install (configuration for) a package repository:
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
