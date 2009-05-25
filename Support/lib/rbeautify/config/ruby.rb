# define ruby language

unless RBeautify::Language.language(:ruby)

  ruby = RBeautify::Language.add_language(:ruby)

  ruby.indent_size = 2

  ruby.add_matcher(:program_end, /^__END__$/, false, :format => false)

  ruby.add_matcher(:multiline_comment, /^=begin/, /^=end/, :format => false)

  ruby.add_matcher(:standard,
                   /((^(module|class|def))|\bdo)\b/,
                   /(^|;\s*)(end|rescue|ensure)\b/)

  ruby.add_matcher(:implicit_end,
                   /^(public|protected|private)$/,
                   /^(public|protected|private)(\s*)?(#.*)?$/,
                   :end => :implicit)

  ruby.add_matcher(:more,
                   /(=\s+|^)(until|for|while)\b/,
                   /(^|;\s*)end\b/)

  ruby.add_matcher(:begin,
                   /((=\s+|^)begin)|(^(ensure|rescue))\b/,
                   /(^|;\s*)(end|rescue|ensure)\b/)

  ruby.add_matcher(:if,
                   /(((^|;\s*)(if|elsif|else|unless))|\bthen)\b/,
                   /((^|;\s*)(elsif|else|end)|\bthen)\b/,
                   :nest_except => [:case])

  ruby.add_matcher(:case,
                   /\bcase\b/,
                   /(^|;\s*)end\b/)

  ruby.add_matcher(:inner_case,
                   /((^|;\s*)(when|else)|\bthen)\b/,
                   /((^|;\s*)(when|else)|\bthen)\b/,
                   :nest_only => [:case],
                   :end => :implicit,
                   :end_can_also_be_start => true)

  bracket_indent_end_line_proc = Proc.new { |block| !block.after_match.empty?}
  bracket_indent_size_proc = Proc.new do |block|
    unless block.after_match.empty?
      strict_ancestors_on_same_line = block.ancestors.select { |a| a != block && a.line_number == block.line_number }
      block.end_offset - strict_ancestors_on_same_line.inject(0) { |sum, a| sum + a.indent_size }
    end
  end

  ruby.add_matcher(:curly_bracket,
                   /\{\s*/,
                   /\}/,
                   :indent_end_line => bracket_indent_end_line_proc,
                   :indent_size => bracket_indent_size_proc)

  ruby.add_matcher(:round_bracket,
                   /\(\s*/,
                   /\)/,
                   :indent_end_line => bracket_indent_end_line_proc,
                   :indent_size => bracket_indent_size_proc)

  ruby.add_matcher(:square_bracket,
                   /\[\s*/,
                   /\]/,
                   :indent_end_line => bracket_indent_end_line_proc,
                   :indent_size => bracket_indent_size_proc)

  ruby.add_matcher(:double_quote,
                   /"/,
                   /"/,
                   :format => false,
                   :escape_character => true)

  ruby.add_matcher(:single_quote,
                   /'/,
                   /'/,
                   :format => false,
                   :escape_character => true)

  ruby.add_matcher(:regex,
                   /(^|(.*,\s*))\//,
                   /\//,
                   :format => false,
                   :escape_character => true,
                   :end_can_also_be_start => false)

  ruby.add_matcher(:back_tick,
                   /`/,
                   /`/,
                   :format => false,
                   :escape_character => true)

  ruby.add_matcher(:comment, /(\s*)?#/,
    /$/,
    :format => false,
    :nest_except => [:double_quote, :single_quote, :regex, :back_tick])

  ruby.add_matcher(:continuing_line,
                   /(,|\.|\+|-|=\>|&&|\|\||\\|==|\s\?|:)(\s*)?(#.*)?$/,
                   /(^|(,|\.|\+|-|=\>|&&|\|\||\\|==|\s\?|:)(\s*)?)(#.*)?$/,
                   :indent_end_line => true,
                   :negate_ends_match => true,
                   :nest_except => [:continuing_line, :curly_bracket, :round_bracket, :square_bracket])

end
