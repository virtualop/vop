show :display_type => :data

run do
  {
    plugins: @op.list_plugins.map { |p| p[:name] }.sort,
    search_path: @op.show_search_path,
    core_path: @op.core_path
  }
end
