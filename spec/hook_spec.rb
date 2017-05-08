require "spec_helper"

RSpec.describe "hooks" do
  include SpecHelper
  before(:example) do
    prepare
    @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "hook_spec", "content" => PLUGIN_WITH_INIT_COUNT)
  end


PLUGIN_WITH_INIT_COUNT = <<'EOF'
on :init do |plugin|
  plugin.state[:init_count] = (plugin.state[:init_count] || 0) + 1
end

on :before_execute do |plugin|
  plugin.state[:before_hook] = (plugin.state[:before_hook] || 0) + 1
end
EOF

INIT_COUNT_ACCESS_COMMAND = <<'EOF'
run do |plugin|
  plugin.state[:init_count]
end
EOF

BEFORE_HOOK_ACCESS_COMMAND = <<'EOF'
run do |plugin|
  plugin.state[:before_hook]
end
EOF

  it "calls init (only once)" do
    @vop.new_command("plugin" => "hook_spec", "name" => "show_init_count", "content" => INIT_COUNT_ACCESS_COMMAND)
    expect(@vop.list_commands.map { |x| x[:name]} ).to include "show_init_count"
    expect(@vop.show_init_count).to be 1
  end

  it "calls core hooks defined in plugins" do
    @vop.new_command("plugin" => "hook_spec", "name" => "before_hook", "content" => BEFORE_HOOK_ACCESS_COMMAND)
    expect(@vop.before_hook).to be > 1
  end

end
