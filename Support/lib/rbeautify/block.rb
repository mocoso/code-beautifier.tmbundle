module RBeautify

  Block = Struct.new(:block_matcher)

  class Block

    def ended_blocks(string, stack)
      block_matcher.ended_blocks(string, self, stack)
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
