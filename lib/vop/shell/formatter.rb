require 'pp'
require 'terminal-table'

def detect_display_type(command, data)
  if data.is_a? Array
    first_row = data.first
    if first_row.is_a? Hash
      :table
    else
      :list
    end
  elsif data.is_a? Hash
    :hash
  else
    :raw
  end
end

def format_output(command, data)
  display_type = command.show_options[:display_type] || detect_display_type(command, data)

  result = data # might get sorted later

  case display_type
  when :table
    # show all columns unless defined otherwise in the command
      columns_to_display =
      if command.show_options.include? :columns
        command.show_options[:columns]
      else
        first_row = data.first
        first_row.keys
      end

    # add an index column
    column_headers = [ '#' ] + columns_to_display

    # array of hashes -> array of arrays
    rearranged = []
    data.each_with_index do |row, index|
      values = [ ]
      columns_to_display.each do |key|
        values << row[key]
      end
      rearranged << values
    end

    # sort
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

    result = rearranged.clone

    # add the index column after sorting
    rearranged.each_with_index do |row, index|
      row.unshift index
    end

    puts Terminal::Table.new(
      rows: rearranged,
      headings: column_headers
    )
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

  [ display_type, result ]
end
