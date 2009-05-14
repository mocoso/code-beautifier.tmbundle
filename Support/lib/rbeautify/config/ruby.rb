# define ruby language

unless RBeautify::Language.language(:ruby)

  ruby = RBeautify::Language.add_language(:ruby)

  ruby.indent_size = 2

  ruby.add_matcher(:program_end, /^__END__$/, false, :format => false)

  ruby.add_matcher(:multiline_comment, /^=begin/, /^=end/, :format => false)

  ruby.add_matcher(:standard,
                   /((^(module|class|def|else))|\bdo)\b/,
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

  ruby.add_matcher(:if_and_case,
                   /(((^|;\s*)(if|elsif|case|unless))|(\b(when|then)))\b/,
                   /((^|;\s*)(elsif|else|end)|\b(when|then))\b/)

  bracket_indent_line_proc = Proc.new { |block| block.end_offset != 0 }
  bracket_indent_size_proc = Proc.new do |block|
    block.start_offset + block.start_match.length unless block.after_start_match.empty?
  end

  ruby.add_matcher(:curly_bracket,
                   /\{\s*/,
                   /\}/,
                   :indent_end_line => bracket_indent_line_proc,
                   :indent_size => bracket_indent_size_proc)

  ruby.add_matcher(:round_bracket,
                   /\(\s*/,
                   /\)/,
                   :indent_end_line => bracket_indent_line_proc,
                   :indent_size => bracket_indent_size_proc)

  ruby.add_matcher(:square_bracket,
                   /\[\s*/,
                   /\]/,
                   :indent_end_line => bracket_indent_line_proc,
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
                   :escape_character => true)

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
