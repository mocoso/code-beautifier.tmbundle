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
      STANDARD_MATCHER            = BlockMatcher.new(/((^(module|class|def|else))|\bdo)\b/, /(^|;\s*)(end|rescue|ensure)\b/),
      IMPLICIT_END_MATCHER        = BlockMatcher.new(/^(public|protected|private)$/, /^(public|protected|private)$/, :end => :implicit),
      MORE_MATCHERS               = BlockMatcher.new(/(=\s+|^)(until|for|while)\b/, /(^|;\s*)end\b/),
      BEGIN_MATCHERS              = BlockMatcher.new(/((=\s+|^)begin)|(^(ensure|rescue))\b/, /(^|;\s*)(end|rescue|ensure)\b/),
      IF_AND_CASE_MATCHER         = BlockMatcher.new(/(((^|;\s*)(if|elsif|case|unless))|(\b(when|then)))\b/, /((^|;\s*)(elsif|else|end)|\b(when|then))\b/),
      CURLY_BRACKET_MATCHER       = BlockMatcher.new(/\{/, /\}/),
      ROUND_BRACKET_MATCHER       = BlockMatcher.new(/\(/, /\)/),
      SQUARE_BRACKET_MATCHER      = BlockMatcher.new(/\[/, /\]/),
      DOUBLE_QUOTE_STRING_MATCHER = BlockMatcher.new(/"/, /"/, :format => false, :escape_character => true),
      SINGLE_QUOTE_STRING_MATCHER = BlockMatcher.new(/'/, /'/, :format => false, :escape_character => true),
      REGEX_MATCHER               = BlockMatcher.new(/\//, /\//, :format => false, :escape_character => true),
      BACK_TICK_MATCHER           = BlockMatcher.new(/`/, /`/, :format => false, :escape_character => true),
      CONTINUING_LINE_MATCHER     = BlockMatcher.new(
        /(,|\.|\+|-|=\>|&&|\|\||\\|==|\s\?|:)$/,
        nil,
        :indent_end_line => true,
        :negate_ends_match => true,
        :nest_except => [:self, CURLY_BRACKET_MATCHER, ROUND_BRACKET_MATCHER, SQUARE_BRACKET_MATCHER]
      )
    ]

    class << self
      def calculate_stack(string, stack = [])
        stack = stack.dup
        current_block = stack.last
        new_block = nil
        block_ended = false

        if current_block
          after_match = current_block.after_end_match(string, stack)
          block_ended = true if after_match
        else
          after_match = nil
        end

        MATCHERS.each do |matcher|
          if matcher.can_nest?(current_block)
            this_after_match = matcher.after_start_match(string)
            if this_after_match && (after_match.nil? || after_match.length <= this_after_match.length)
              if block_ended && after_match.length < this_after_match.length
                block_ended = false
              end
              after_match = this_after_match
              new_block = Block.new(matcher)
            end
          end
        end

        if after_match
          if block_ended
            while ((block = stack.pop) && block.end_is_implicit? && !block.block_matcher.explicit_end_match?(string)); end
          end
          if new_block
            stack << new_block
          end
          stack = calculate_stack(after_match, stack)
        end

        stack
      end
    end

    def indent_end_line?
      options[:indent_end_line]
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

    def after_end_match(string, stack)
      after_match = explicit_after_end_match(string)

      if end_is_implicit? && after_match.nil? && !stack.empty?
        after_match = stack.last.after_end_match(string, stack.slice(0, stack.length - 1))
      end

      after_match
    end

    def after_start_match(string)
      !string.empty? && (match = starts.match(string)) && match.post_match
    end

    # True if blocks can contain the escape character \ which needs to be
    # checked for on end match
    def escape_character?
      options[:escape_character] == true
    end

    private
      def explicit_after_end_match(string)
        after_match = nil

        unless ends == false || string.empty?

          if match = ends.match(string)
            unless options[:negate_ends_match]
              if options[:escape_character] &&
                  ((escape_chars = match.pre_match.match(/\\*$/)) && (escape_chars[0].size % 2 == 1))
                # If there are an odd number of escape characters just before
                # the match then this match should be skipped
                return explicit_after_end_match(match.post_match)
              else
                after_match = match.post_match
              end
            end
          elsif options[:negate_ends_match]
            after_match = string
          end

        end
        after_match
      end

  end

end
