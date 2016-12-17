require "pry"

run do |params|
  @op._pry
  # pry messes up the terminal completion setup by the vop shell backend,
  # so currently this is a one-call command:
  Kernel.exit(42)
end
