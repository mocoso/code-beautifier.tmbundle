module RBeautify

  Block = Struct.new(:block_matcher)

  class Block

    def end?(string)
      block_matcher.end?(string)
    end

    def format?
      block_matcher.format?
    end

    def indent_end_line?
      block_matcher.indent_end_line?
    end

  end

end
