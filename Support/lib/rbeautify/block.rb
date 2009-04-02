module RBeautify

  class Block

    attr_accessor :block_matcher

    def initialize(block_matcher)
      self.block_matcher = block_matcher
    end

    def after_end_match(string, stack)
      block_matcher.after_end_match(string, stack)
    end

    def format?
      block_matcher.format?
    end

    def indent_end_line?
      block_matcher.indent_end_line?
    end

    def end_is_implicit?
      block_matcher.end_is_implicit?
    end

  end

end
