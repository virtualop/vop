require 'pp'
require 'terminal-table'

def format_output(command, data)
  if data.is_a? Array
    first_row = data.first
    if first_row.is_a? Hash
      # show all columns unless defined otherwise in the command
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
    else
      puts data.join("\n")
    end
  elsif data.is_a? Hash
    data.each do |k,v|
      puts "#{k} : #{v}"
    end
  else
    puts data
  end
end
