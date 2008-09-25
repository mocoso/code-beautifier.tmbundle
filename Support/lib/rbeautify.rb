#!/usr/bin/ruby -w

# Based on code by Paul Lutus (http://www.arachnoid.com/ruby/rubyBeautifier.html)

module RBeautify

  def RBeautify.beautify_string(source, path = "")
    dest = ""
    previous_line = nil
    line = nil
    source.split("\n").each do |line_content|
      line = RubyLine.new(line_content, previous_line)
      dest += line.formatted
      previous_line = line
    end

    # TODO: Decide how to inform users of indentation error
    # if(line.tabs != 0)
    #   raise "#{path}: Indentation error: #{line.tabs}"
    # end

    return dest
  end

  def RBeautify.beautify_file(path)
    if(path == '-') # stdin source
      source = STDIN.read
      print beautify_string(source,"stdin")
    else # named file source
      source = File.read(path)
      dest = beautify_string(source,path)
      if(source != dest)
        # make a backup copy
        File.open(path + "~","w") { |f| f.write(source) }
        # overwrite the original
        File.open(path,"w") { |f| f.write(dest) }
      end
    end
  end # beautify_file

  def RBeautify.main
    if(!ARGV[0])
      STDERR.puts "usage: Ruby filenames or \"-\" for stdin."
        exit 0
    end
    ARGV.each do |path|
      RBeautify.beautify_file(path)
    end
  end # main

  class RubyLine

    # tab character and size
    @@tab_char = " "
    @@tab_size = 2

    # indent regexp tests
    BRACKETTED_INDENT_EXP = [
      /\{[^\}]*$/,
      /\[[^\]]*$/,
      /\([^\)]*$/
    ]

    OTHER_INDENT_EXP = [
      /^module\b/,
      /^class\b/,
      /^if\b/,
      /(=\s*|^)until\b/,
      /(=\s*|^)for\b/,
      /^unless\b/,
      /(=\s*|^)while\b/,
      /(=\s*|^)begin\b/,
      /(^| )case\b/,
      /\bthen\b/,
      /^rescue\b/,
      /^def\b/,
      /\bdo\b/,
      /^else\b/,
      /^elsif\b/,
      /^ensure\b/,
      /\bwhen\b/
    ]

    # outdent regexp tests
    OUTDENT_EXP = [
      /^rescue\b/,
      /^ensure\b/,
      /^elsif\b/,
      /^end\b/,
      /^else\b/,
      /\bwhen\b/,
      /^[^\{]*\}/,
      /^[^\[]*\]/,
      /^[^\(]*\)/
    ]

    # ignore regexp tests
    IGNORE_EXP = [
      /\{[^\{]*?\}/,
      /\[[^\[]*?\]/,
      /'.*?'/,
      /".*?"/,
      /\`.*?\`/,
      /\([^\(]*?\)/,
      /\/.*?\//,
      /%r(.).*?\1/,
      /#[^\"]+$/ # ignore end-of-line comments
    ]

    attr_writer :tabs
    attr_accessor :content, :previous_line

    def initialize(content, previous_line)
      self.content = content
      self.previous_line = previous_line
    end

    def formatted
      if program_ended? || multiline_comment?
        content + "\n"
      else
        if stripped.length > 0
          tab_string + stripped + "\n"
        else
          "\n"
        end
      end
    end

    def tabs
      unless @tabs.nil?
        return @tabs
      end

      if previous_line.nil?
        @tabs = 0
      elsif previous_line.indent?
        @tabs = previous_line.tabs + 1
      else
        @tabs = previous_line.tabs
      end

      if outdent?
        @tabs = @tabs - 1
      end

      @tabs
    end

    def parent
      unless @parent.nil?
        return @parent
      end

      if previous_line
        if previous_line.indent?
          @parent = previous_line
        else
          @parent = previous_line.parent
        end

        if outdent?
          @parent = @parent && @parent.parent
        end
      else
        @parent = nil
      end

      return @parent
    end

    protected
    def tab_string
      if previous_line && previous_line.has_following_line? && (parent.nil? || !parent.bracketted_indent?)
        number_of_tabs = tabs + 1
      else
        number_of_tabs = tabs
      end

      return (number_of_tabs < 0)? "" : @@tab_char * @@tab_size * number_of_tabs
    end

    def indent?
      @indent ||= !OTHER_INDENT_EXP.detect { |re| re.match(indent_relevant_content) && !(/\s+end\s*$/.match(indent_relevant_content)) }.nil?  || bracketted_indent?
    end

    def bracketted_indent?
      @bracketted_indent ||= !BRACKETTED_INDENT_EXP.detect { |re| re.match(indent_relevant_content) }.nil?
    end

    def outdent?
      @outdent ||= !OUTDENT_EXP.detect { |re| re.match(indent_relevant_content) }.nil?
    end

    def program_ended?
      @program_ended ||= ((previous_line && previous_line.program_ended?) || /^__END__$/.match(content))
    end

    def multiline_comment?
      @multiline_comment ||= ((previous_line && previous_line.multiline_comment? && !previous_line.end_of_multline_comment?) || /^=begin/.match(stripped))
    end

    def has_non_comment_content?
      !(stripped.empty? || /^\#/.match(stripped))
    end

    def end_of_multline_comment?
      /^=end/.match(stripped)
    end

    def has_following_line?
      @has_following_line ||= (previous_line && previous_line.has_following_line? && !has_non_comment_content?) || /[^\\]\\\s*$/.match(indent_relevant_content) || /(,|\.|\+|=\>)$/.match(indent_relevant_content)
    end

    def stripped
      @stripped = content.strip
    end

    def indent_relevant_content
      unless @indent_relevant_content.nil?
        return @indent_relevant_content
      end

      if program_ended? || multiline_comment?
        @indent_relevant_content = ''
      else
        @indent_relevant_content  = stripped.dup
        IGNORE_EXP.each do |re|
          @indent_relevant_content.gsub!(re,"")
        end
        # convert quotes
        @indent_relevant_content.gsub!(/\\\"/,"'")
        @indent_relevant_content
      end
    end

  end

end # module RBeautify

# if launched as a standalone program, not loaded as a module
if __FILE__ == $0
  RBeautify.main
end
