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
            potential_value = row[key.to_s] || row[key.to_sym]
            if potential_value.nil?
              $logger.warn "column '#{key}' not found in result data"
            else
              values << (potential_value)
            end
          end unless row.nil?
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
        sorted = data.sort_by { |e| e.id }

        blacklisted_keys = %w|name params plugin_name|
        all_keys = sorted.map { |x| x.data.keys }.flatten.uniq
        columns = all_keys.delete_if { |x| blacklisted_keys.include? x }

        headers = [ sorted.first.key ] + columns

        rows = sorted.map do |entity|
          row = [ entity.id ]

          columns.each do |column|
            value = entity.data[column] || ""
            row << (value.respond_to?(to_s) ? value.to_s[0..49] : value)
          end

          row
        end

        Terminal::Table.new(
          rows: rows,
          headings: headers
        )
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
