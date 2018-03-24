require "spec_helper"
require 'stringio'

RSpec.describe Vop::Shell do

  before(:example) do
    @vop = test_vop("shell_spec")
    @shell = ::Vop::Shell.new(@vop)
    @formatter = ::Vop::ShellFormatter.new
  end

  def prepare(command_name)
    request = ::Vop::Request.new(@vop, command_name)
    request.shell = Vop::Shell.new(@vop)
    response = @vop.execute_request(request)

    [request, response]
  end

  def display_type(command_name)
    request = ::Vop::Request.new(@vop, command_name)
    request.shell = Vop::Shell.new(@vop)
    response = @vop.execute_request(request)

    @formatter.analyze(request, response)
  end

  def format(command_name)
    request, response = prepare(command_name)
    dt = display_type(command_name)
    @formatter.format(request, response, dt)
  end

  def redirecting_stdout(&block)
    new_stdout = StringIO.new
    $stdout = new_stdout

    yield

    $stdout = STDOUT
    new_stdout.string
  end

  def shell(command)
    redirecting_stdout do
      @shell.parse_and_execute(command)
    end
  end

  def parse_table(command_name)
    formatted = format(command_name).to_s.lines
    # lines 0 and 2 are decoration
    header = formatted[1]
    first_line = formatted[3]
    puts "header : #{header}"
    puts "first line : #{first_line}"

    header_fields = header.split("|").map(&:strip).select { |x| x != '#' && x != '' }
    columns = first_line.split("|").map(&:strip).select { |x| x.to_s != '' }

    [header_fields, columns]
  end

  it "executes commands like a REPL" do

    # PTY.spawn('') do |output, input|
    #   output.readpartial 1024 # read past the prompt
    # end
    $logger.info "shell_spec"
    Vop::Shell.run(nil, 'list_plugins')
  end

  it "passes on arguments" do
    Vop::Shell.run(nil, 'list_contributors machine')
  end

  it "auto-detects Hash display type" do
    expect(display_type("return_hash")).to eql(:hash)
  end

  it "applies explicit display types" do
    expect(display_type("explicit_display_type")).to eql(:raw)
  end

  it "displays arrays of hashes as tables" do
    expect(display_type("table")).to eql(:table)
  end

  it "detects entity lists" do
    expect(display_type("some_entities")).to eql(:entity_list)
  end

  it "detects single entities" do
    expect(display_type("entity")).to eql(:entity)
  end

  it "defaults to displaying raw values" do
    expect(display_type("so_raw")).to eql(:raw)
  end

  it "displays raw values as is" do
    formatted = format("so_raw")
    expect(formatted).to eql(42)
  end

  it "displays tables" do
    header_fields, columns = parse_table("table")

    expect(header_fields).to eql(["foo"])
    expect(columns).to eql(["0", "snafoo"])
  end

  it "displays specific columns" do
    header_fields, columns = parse_table("table_with_explicit_columns")

    expect(header_fields).to eql(["bar", "baz"])
    expect(columns).to eql(["0", "2", "3"])
  end

  it "displays hashes" do
    formatted = format("return_hash")
    expect(formatted).to eql("foo : bar")
  end

  it "displays data prettily" do
    formatted = format("floral_bonnet")
    expect(formatted.strip).to eql('{:foo=>"zaphod"}')
  end

  it "complains about invalid display types" do
    expect {
      formatted = format("invalid_display_type")
    }.to raise_error /unknown display type/
  end

  # TODO sorting does not work if data types differ over multiple rows

  it "passes through ruby commands to @op" do
    @shell.parse_and_execute("@op.list_plugins")
  end

  it "does handle unknown @-commands" do
    output = redirecting_stdout do
      @shell.parse_and_execute("@foo")
    end
    expect(output).to include("unknown @-command")
  end

  it "shows help when a command ends in a question mark" do
    output = redirecting_stdout do
      @shell.parse_and_execute("list_plugins?")
    end
    expect(output).to include("syntax")
  end

  it "does not crash on unknown commands" do
    output = shell("slartibartfast")
    expect(output).to start_with("unknown command")
  end

  it "does tab-completion for the list of commands" do
    lookups = @shell.tab_completion("")
    expect(lookups).to include("list_plugins")
  end

end
