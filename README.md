# Vop

The vop is a systems automation scripting framework.

## Installation

### as a gem library for Ruby:

Install via `gem`:

    $ gem install vop

or add this dependency to your `Gemfile`:
```ruby
gem 'vop'
```

(and then run `bundle`)

## Usage

Call `vop` to start the shell.

Use the tab key for completion, type "help" for more info, "list_plugins" and "list_commands" for an overview/inspiration.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### without building gems

The launcher/wrapper script `exe/vop` checks for the presence of the environment variable
`VOP_DEV_MODE` - if it is set, the "lib/" directory next to the script is added to the library
path, and the vop is loaded from there (no gem install needed).

## Syntax

### Plugins

required:
one (potentially empty) file called "<name>.plugin"

optional:
```
description "really nice plugin, this one"

auto_load false    # default is true

depends_on :other_plugin
depends_on [ :foo, :bar, :baz ]
```

### Commands

minimal:
```
run { 42 }
```

optional:
```
description "Roses are red."

read_only   # => cacheable
```

defining params:
```
param "snafoo"    # optional
param! "snafoo"   # mandatory
param! :snafoo    # entity

param[!] ( "name" | :entity ) [, {option: value}]

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

### Services

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/virtualop/vop.
