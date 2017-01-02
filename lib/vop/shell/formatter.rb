require 'pp'
require 'terminal-table'

def detect_display_type(command, data)
  if data.is_a? Array
    first_row = data.first
    if first_row.is_a? Hash
      display_type = :table
    else
      display_type = :list
    end
  elsif data.is_a? Hash
    display_type = :hash
  else
    display_type = :raw
  end
end

def format_output(command, data)
  display_type = command.show_options[:display_type] || detect_display_type(command, data)

  case display_type
  when :table
    # show all columns unless defined otherwise in the command
    first_row = data.first
    columns_to_display = first_row.keys
    if command.show_options.include? :columns
      columns_to_display = command.show_options[:columns]
    end
    column_headers = columns_to_display

    rearranged = [] # array of hashes -> array of arrays
    data.each do |row|
      values = []
      columns_to_display.each do |key|
        values << row[key]
      end
      rearranged << values
    end

    begin
      rearranged.sort_by! { |row| row.first }
    rescue
      puts "[WARN] ran into trouble sorting the result (by the first column); results may be not quite sorted."
      begin
        rearranged.sort_by! { |row| row.first || "zaphod" }
      rescue
        puts "[SHRUG] could not sort even when accounting for potential nil values, giving up."
      end
    end

    puts Terminal::Table.new rows: rearranged, headings: column_headers
  when :list
    puts data.join("\n")
  when :hash
    data.each do |k,v|
      puts "#{k} : #{v}"
    end
  when :raw
    puts data
  when :data
    pp data
  else
    raise "unknown display type #{display_type}"
  end
end
