require "terminal-table"

module Vop

  class ShellFormatter

    def analyze(request, response)
      data = response.result

      if request.command.show_options[:display_type]
        # TODO check that display_type is valid
        request.command.show_options[:display_type]
      else
        if data.is_a? Array
          first_row = data.first
          if first_row.is_a? Hash
            :table
          elsif first_row.is_a? Entity
            :entity_list
          else
            :list
          end
        elsif data.is_a? Hash
          :hash
        elsif data.is_a? Entity
          :entity
        else
          :raw
        end
      end
    end

    def format(request, response, display_type)
      data = response.result
      command = request.command

      result = case display_type
      when :table
        columns_to_display =
          if command.show_options.include? :columns
            command.show_options[:columns]
          else
            # TODO this is not optimal - what if the second row has more keys than the first?
            first_row = data.first
            first_row.keys
          end

        # add an index column
        column_headers = [ '#' ] + columns_to_display

        # array of hashes -> array of arrays
        rearranged = []
        data.each do |row|
          values = [ ]
          columns_to_display.each do |key|
            values << (row[key.to_s] || row[key.to_sym])
          end
          rearranged << values
        end

        rearranged.sort_by! { |row| row.first || "" }

        # add the index column after sorting
        rearranged.each_with_index do |row, index|
          row.unshift index
        end

        Terminal::Table.new(
          rows: rearranged,
          headings: column_headers
        )
      when :list
        data.join("\n")
      when :hash
        data.map do |k,v|
          "#{k} : #{v}"
        end.join("\n")
      when :entity_list
        data.sort_by { |e| e.id }.map do |entity|
          attributes = entity.data.sort_by do |x|

          end.map do |key, value|
            if key == entity.key
              nil
            else
              "#{key} : #{value}"
            end
          end.compact.join("\n  ")
          "[#{entity.type}] #{entity.id}\n  #{attributes}"
        end.join("\n")
      when :entity
        entity = data
        "[#{entity.type}] #{entity.id}"
      when :raw
        data
      when :data
        data.pretty_inspect
      else
        raise "unknown display type #{display_type}"
      end

      result
    end

  end

end
