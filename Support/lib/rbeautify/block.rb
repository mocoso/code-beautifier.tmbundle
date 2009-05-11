module RBeautify

  class Block

    attr_accessor :block_matcher, :start_offset, :start_match, :after_start_match, :end_offset

    def initialize(block_matcher, start_offset, start_match, after_start_match)
      self.block_matcher = block_matcher
      self.start_offset = start_offset
      self.start_match = start_match
      self.after_start_match = after_start_match
    end

    def after_end_match(string, stack, offset)
      self.end_offset, after_match = block_matcher.end_match(string, stack, offset)
      after_match
    end

    def format?
      block_matcher.format?
    end

    def indent_end_line?
      block_matcher.indent_end_line?(self)
    end

    def indent_size
      block_matcher.indent_size(self)
    end

    def end_is_implicit?
      block_matcher.end_is_implicit?
    end

    def ==(other)
      self.block_matcher == other.block_matcher &&
        self.after_start_match == other.after_start_match &&
        self.start_offset == other.start_offset &&
        self.end_offset == other.end_offset
    end
  end

end
