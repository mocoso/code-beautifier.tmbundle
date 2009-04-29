module RBeautify

  class Line

    # tab character and size
    @@tab_char = " "
    @@tab_size = 2

    attr_accessor :content, :original_stack

    def initialize(content, original_stack = [])
      self.content = content
      self.original_stack = original_stack
    end

    def format
      if @formatted.nil?
        if format?
          if stripped.length == 0
            @formatted = ""
          else
            @formatted = tab_string + stripped
          end
        else
          @formatted = content
        end
      end

      @formatted
    end

    def stack
      @stack ||= BlockMatcher.calculate_stack(stripped, original_stack)
    end

    private
      def format?
        original_stack.last.nil? || original_stack.last.format?
      end

      def tabs
        if (original_stack.size > stack.size) && (original_stack.last && original_stack.last.indent_end_line?)
          original_stack.size
        else
          (original_stack & stack).size
        end
      end

      def tab_string
        @@tab_char * @@tab_size * tabs
      end

      def stripped
        @stripped = content.strip
      end

  end

end
