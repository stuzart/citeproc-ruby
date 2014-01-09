module CiteProc
  module Ruby

    class Renderer

      # @param item [CiteProc::CitationItem]
      # @param node [CSL::Style::Names]
      # @return [String]
      def render_names(item, node)
        return '' unless node.has_variable?

        names = node.variable.split(/\s+/).map do |role|
          [role.to_sym, item.data[role]]
        end

        names.reject! { |n| n[1].nil? || n[1].empty? }

        if names.empty?
          return '' unless node.has_substitute?

          # TODO substitution

        else

          resolve_editor_translator_exception! names
          name = node.name || CSL::Style::Name.new

          rendition = names.map { |role, ns|
            if node.has_label?
              render_name(ns, name) << render_label(item, node.label, role)
            else
              render_name ns, name
            end

          }.join(node.delimiter)

          format rendition, node
        end
      end

      # Formats one or more names according to the
      # configuration of the passed-in node.
      # Returns the formatted name(s) as a string.
      #
      # @param names [CiteProc::Names]
      # @param node [CSL::Style::Name]
      # @return [String]
      def render_name(names, node)

        delimiter = node.delimiter

        connector = node.connector
        connector = translate('and') if connector == 'text'

        # Add spaces around connector
        connector = " #{connector} " unless connector.nil?

        rendition = case
          when node.truncate?(names)
            truncated = node.truncate(names)

            if node.delimiter_precedes_last?(truncated)
              connector = [delimiter, connector].compact.join('').squeeze(' ')
            end

            if node.ellipsis? && names.length - truncated.length > 1
              [
                truncated.map.with_index { |name, idx|
                  render_individual_name name, node, idx + 1
                }.join(delimiter),

                render_individual_name(names[-1], node, truncated.length + 1)

              ].join(node.ellipsis)

            else
              [
                truncated[0...-1].map.with_index { |name, idx|
                  render_individual_name name, node, idx + 1
                }.join(delimiter),

                render_individual_name(truncated[-1], node, truncated.length)

              ].join(connector || delimiter)

            end

          when names.length < 3
            if node.delimiter_precedes_last?(names)
              connector = [delimiter, connector].compact.join('').squeeze(' ')
            end

            names.map.with_index { |name, idx|
              render_individual_name name, node, idx + 1
            }.join(connector || delimiter)

          else
            if node.delimiter_precedes_last?(names)
              connector = [delimiter, connector].compact.join('').squeeze(' ')
            end

            [
              names[0...-1].map.with_index { |name, idx|
                render_individual_name name, node, idx + 1
              }.join(delimiter),

              render_individual_name(names[-1], node, names.length)

            ].join(connector || delimiter)
          end

        format rendition, node
      end

      # @param names [CiteProc::Name]
      # @param node [CSL::Style::Name]
      # @param position [Fixnum]
      # @return [String]
      def render_individual_name(name, node, position = 1)
        if name.personal?
          name = name.dup

          node.name_part.each do |part|
            case part.name
            when 'family'
              name.family = format(name.family, part)
            when 'given'
              name.given = format(name.given, part)
            end
          end

          name.options.merge! node.name_options
          name.sort_order! node.name_as_sort_order_at?(position)
        end

        format name.to_s, node
      end

      private

      def resolve_editor_translator_exception!(names)

        translator = names.detect { |role, _| role == :translator }
        return names if translator.nil?

        editor = names.detect { |role, _| role == :editor }
        return names if editor.nil?

        # TODO

        names
      end
    end

  end
end
