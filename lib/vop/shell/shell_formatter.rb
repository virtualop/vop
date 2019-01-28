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
      show_options = command.show_options

      result = case display_type
      when :table
        columns_to_display =
          if show_options[:columns]
            show_options[:columns]
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

        unless show_options.include?(:sort) && show_options[:sort] == false
          rearranged.sort_by! { |row| row.first || "" }
        end

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
          attributes = entity.data.map do |key, value|
            if key == entity.key
              nil
            else
              "#{key} : #{value}"
            end
          end.compact

          output = "[#{entity.type}] #{entity.id}"
          if attributes
            output += "\n" + attributes.join("\n")
          end
          output
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
