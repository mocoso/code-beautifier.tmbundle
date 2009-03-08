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
      PROGRAM_END_MATCHER       = BlockMatcher.new(/^__END__$/, false, :format => false),
      MULTILINE_COMMENT_MATCHER = BlockMatcher.new(/^=begin/, /^=end/, :format => false),
      STANDARD_MATCHER          = BlockMatcher.new(/(((^(module|class|def|unless|else))|\bdo)\b)(?!.*\bend(\b|$))/, /^(end|rescue)\b/),
      IMPLICIT_END_MATCHER      = BlockMatcher.new(/^(public|protected|private)$/, false, :end => :implicit),
      MORE_MATCHERS             = BlockMatcher.new(/(=\s*|^)(until|for|while)\b/, /^end\b/),
      BEGIN_MATCHERS            = BlockMatcher.new(/((=\s*|^)begin)|(^(ensure|rescue))\b/, /^(end|rescue|ensure)\b/),
      CASE_MATCHER              = BlockMatcher.new(/(((^| )case)|(\bwhen))\b/, /^(when|else|end)\b/),
      IF_MATCHER                = BlockMatcher.new(/((^(if|elsif))|(\bthen))\b/, /^(elsif|else|end)\b/),
      CURLY_BRACKET_MATCHER     = BlockMatcher.new(/\{[^\}]*$/, /^[^\{]*\}/),
      ROUND_BRACKET_MATCHER     = BlockMatcher.new(/\([^\)]*$/, /^[^\(]*\)/),
      SQUARE_BRACKET_MATCHER    = BlockMatcher.new(/\[[^\]]*$/, /^[^\[]*\]/),
      MULTILINE_STRING_MATCHER  = BlockMatcher.new(/"/, /"/, :format => false),
      MULTILINE_MATCHER         = BlockMatcher.new(
        /(,|\.|\+|-|=\>|&&|\|\||\\|==)$/,
        nil,
        :indent_end_line => true,
        :negate_ends_match => true,
        :nest_except => [:self, CURLY_BRACKET_MATCHER, ROUND_BRACKET_MATCHER, SQUARE_BRACKET_MATCHER]
      )
    ]

    def block(string, parent_block)
      if can_nest?(parent_block) && starts.match(string)
        Block.new(self)
      else
        nil
      end
    end

    def end?(string, stack)
      if end_is_implicit? && stack && !stack.empty?
        return stack.last.end?(string, stack.slice(0, stack.length - 1))

      else
        if ends == false
          # nil indicates no end to block
          return false

        elsif options[:negate_ends_match]
          # false indicates should be opposite of match which started block
          return !ends.match(string)

        else
          ends.match(string)
        end

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

  end

end
