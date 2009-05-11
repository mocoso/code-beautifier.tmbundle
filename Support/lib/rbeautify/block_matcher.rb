module RBeautify

  class BlockMatcher

    attr_accessor :starts, :ends, :options

    def initialize(starts, ends, options = {})
      self.starts = starts
      self.ends = ends.nil? ? starts : ends

      if options[:nest_except]
        options[:nest_except] = options[:nest_except].map{ |m| m == :self ? self : m }
      end

      self.options = options
    end

    MATCHERS = [
      PROGRAM_END_MATCHER         = BlockMatcher.new(/^__END__$/, false, :format => false),
      MULTILINE_COMMENT_MATCHER   = BlockMatcher.new(/^=begin/, /^=end/, :format => false),

      STANDARD_MATCHER            = BlockMatcher.new(/((^(module|class|def|else))|\bdo)\b/,
                                                     /(^|;\s*)(end|rescue|ensure)\b/),

      IMPLICIT_END_MATCHER        = BlockMatcher.new(/^(public|protected|private)$/,
                                                     /^(public|protected|private)(\s*)?(#.*)?$/,
                                                     :end => :implicit),

      MORE_MATCHERS               = BlockMatcher.new(/(=\s+|^)(until|for|while)\b/, /(^|;\s*)end\b/),

      BEGIN_MATCHERS              = BlockMatcher.new(/((=\s+|^)begin)|(^(ensure|rescue))\b/,
                                                     /(^|;\s*)(end|rescue|ensure)\b/),

      IF_AND_CASE_MATCHER         = BlockMatcher.new(/(((^|;\s*)(if|elsif|case|unless))|(\b(when|then)))\b/,
                                                     /((^|;\s*)(elsif|else|end)|\b(when|then))\b/),

      CURLY_BRACKET_MATCHER       = BlockMatcher.new(/\{\s*/, /\}/,
                                                     :indent_end_line => Proc.new { |block| block.end_offset != 0 },
                                                     :indent_size => Proc.new { |block| block.start_offset + block.start_match.length unless block.after_start_match.empty? }),

      ROUND_BRACKET_MATCHER       = BlockMatcher.new(/\(\s*/, /\)/,
                                                     :indent_end_line => Proc.new { |block| block.end_offset != 0 },
                                                     :indent_size => Proc.new { |block| block.start_offset + block.start_match.length unless block.after_start_match.empty? }),

      SQUARE_BRACKET_MATCHER      = BlockMatcher.new(/\[\s*/, /\]/,
                                                     :indent_end_line => Proc.new { |block| block.end_offset != 0 },
                                                     :indent_size => Proc.new { |block| block.start_offset + block.start_match.length unless block.after_start_match.empty? }),

      DOUBLE_QUOTE_STRING_MATCHER = BlockMatcher.new(/"/, /"/, :format => false, :escape_character => true),
      SINGLE_QUOTE_STRING_MATCHER = BlockMatcher.new(/'/, /'/, :format => false, :escape_character => true),

      REGEX_MATCHER               = BlockMatcher.new(/(^|(.*,\s*))\//, /\//,
                                                     :format => false,
                                                     :escape_character => true),

      BACK_TICK_MATCHER           = BlockMatcher.new(/`/, /`/, :format => false, :escape_character => true),

      COMMENT_MATCHER             = BlockMatcher.new(
        /(\s*)?#/,
        /$/,
        :format => false,
        :nest_except => [DOUBLE_QUOTE_STRING_MATCHER, SINGLE_QUOTE_STRING_MATCHER, REGEX_MATCHER, BACK_TICK_MATCHER]
      ),

      CONTINUING_LINE_MATCHER     = BlockMatcher.new(
        /(,|\.|\+|-|=\>|&&|\|\||\\|==|\s\?|:)(\s*)?(#.*)?$/,
        /(^|(,|\.|\+|-|=\>|&&|\|\||\\|==|\s\?|:)(\s*)?)(#.*)?$/,
        :indent_end_line => true,
        :negate_ends_match => true,
        :nest_except => [:self, CURLY_BRACKET_MATCHER, ROUND_BRACKET_MATCHER, SQUARE_BRACKET_MATCHER]
      )
    ]

    class << self
      def calculate_stack(string, stack = [], index = 0)
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

        MATCHERS.each do |matcher|
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
            while ((block = stack.pop) && block.end_is_implicit? && !block.block_matcher.explicit_end_match?(string)); end
          end
          if new_block
            stack << new_block
          end
          stack = calculate_stack(after_match, stack, new_index)
        end

        stack
      end
    end

    def indent_end_line?(block)
      evaluate_option_for_block(:indent_end_line, block)
    end

    def indent_size(block)
      evaluate_option_for_block(:indent_size, block) || 2
    end

    def format?
      options[:format] != false
    end

    def can_nest?(parent_block)
      parent_block.nil? ||
        (parent_block.format? && (options[:nest_except].nil? || !options[:nest_except].include?(parent_block.block_matcher)))
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
