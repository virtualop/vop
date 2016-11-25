class Loader

  attr_reader :loaded

  def initialize(op, plugin)
    @op = op
    @plugin = plugin
    @loaded = []

    # TODO plugin.load_helper_classes(self) unless plugin == nil
  end

  def from_scratch(name)
    fresh = { "name" => name }
    @loaded << fresh
  end

  def self.read(op, plugin, name, source, file_name = nil)
    loader = new(op, plugin)

    loader.from_scratch(name)
    begin
      if file_name
        loader.instance_eval source, file_name
      else
        loader.instance_eval source
      end
    rescue => detail
      raise "could not read '#{name}' : #{detail.message}\n#{detail.backtrace[0..9].join("\n")}"
    end

    loader
  end

end
