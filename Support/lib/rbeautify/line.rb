module RBeautify

  class Line

    # indent_character
    @@indent_character = " "

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

      def indent_size
        if (original_stack.size > stack.size) && (original_stack.last && original_stack.last.indent_end_line?)
          self.class.indent_size_for_stack(original_stack)
        else
          self.class.indent_size_for_stack(original_stack & stack)
        end
      end

      def tab_string
        @@indent_character * indent_size
      end

      def stripped
        @stripped = content.strip
      end
      
      def self.indent_size_for_stack(stack)
        stack.map{ |block| block.indent_size}.inject(0) { |sum, indent_size| sum + indent_size }
      end

  end

end
