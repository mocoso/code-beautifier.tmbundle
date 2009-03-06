module RBeautify

  Block = Struct.new(:block_matcher)

  class Block

    def end?(string, stack)
      block_matcher.end?(string, stack)
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
