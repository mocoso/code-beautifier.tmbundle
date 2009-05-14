module RBeautify

  class BlockMatcher

    attr_accessor :language, :name, :starts, :ends, :options

    def initialize(language, name, starts, ends, options = {})
      self.language = language
      self.name = name
      self.starts = starts
      self.ends = ends.nil? ? starts : ends
      self.options = options
    end

    class << self
      def calculate_stack(language, string, stack = [], index = 0)
        stack = stack.dup
        current_block = stack.last
        new_block = nil
        block_ended = false
        new_index = index

        if current_block
          after_match = current_block.after_end_match(string, stack, index)
          if after_match
            block_ended = true
          end
        else
          after_match = nil
        end

        language.matchers.each do |matcher|
          if matcher.can_nest?(current_block)
            started_block_candidate = matcher.block(string, index)
            if started_block_candidate &&
                (after_match.nil? || after_match.length <= started_block_candidate.after_start_match.length)
              if block_ended && after_match.length < started_block_candidate.after_start_match.length
                block_ended = false
              end
              after_match = started_block_candidate.after_start_match
              new_block = started_block_candidate
            end
          end
        end

        if after_match
          new_index = string.length - after_match.length
          if block_ended
            while (
                (block = stack.pop) &&
                block.end_is_implicit? &&
                !block.block_matcher.explicit_end_match?(string)
              )
            end
          end
          if new_block
            stack << new_block
          end
          stack = calculate_stack(language, after_match, stack, new_index)
        end

        stack
      end
    end

    def indent_end_line?(block)
      evaluate_option_for_block(:indent_end_line, block)
    end

    def indent_size(block)
      evaluate_option_for_block(:indent_size, block) || language.indent_size
    end

    def format?
      options[:format] != false
    end

    def can_nest?(parent_block)
      parent_block.nil? ||
        (parent_block.format? && (options[:nest_except].nil? || !options[:nest_except].include?(parent_block.name)))
    end

    def end_is_implicit?
      options[:end] == :implicit
    end

    def explicit_end_match?(string)
      !explicit_after_end_match(string).nil?
    end

    def end_match(string, stack, offset)
      extra_off_set, after_match = explicit_after_end_match(string)

      if after_match
        new_offset = offset + extra_off_set
      else
        new_offset = offset
      end

      if end_is_implicit? && after_match.nil? && stack.size > 1
        rest_of_stack = stack.slice(0, stack.length - 1)
        after_match = rest_of_stack.last.after_end_match(string, rest_of_stack, 0)
        new_offset = rest_of_stack.last.end_offset
      end

      if after_match
        return new_offset, after_match
      else
        return nil
      end
    end

    def block(string, index)
      !string.empty? && (match = starts.match(string)) && Block.new(self, index + match.begin(0), match[0], match.post_match)
    end

    # True if blocks can contain the escape character \ which needs to be
    # checked for on end match
    def escape_character?
      options[:escape_character] == true
    end

    private
      def explicit_after_end_match(string)
        after_match = nil

        unless ends == false

          if match = ends.match(string)
            unless options[:negate_ends_match]
              if options[:escape_character] &&
                  ((escape_chars = match.pre_match.match(/\\*$/)) && (escape_chars[0].size % 2 == 1))
                # If there are an odd number of escape characters just before
                # the match then this match should be skipped
                return explicit_after_end_match(match.post_match)
              else
                after_match = match.post_match
                index = match.begin(0)
              end
            end
          elsif options[:negate_ends_match]
            after_match = string
            index = 0
          end

        end

        if after_match
          return index, after_match
        else
          return nil
        end
      end

      def evaluate_option_for_block(key, block)
        if options[key] && options[key].respond_to?(:call)
          options[key].call(block)
        else
          options[key]
        end
      end

  end

end
