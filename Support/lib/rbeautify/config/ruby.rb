# define ruby language

unless RBeautify::Language.language(:ruby)

  ruby = RBeautify::Language.add_language(:ruby)

  pre_keyword_boundary = '(^|[^a-z0-9A-Z:.])' # like \b but with : and . added

  ruby.indent_size = 2

  ruby.add_matcher(:program_end, /^__END__$/, false, :format => false)

  ruby.add_matcher(:multiline_comment, /^=begin/, /^=end/, :format => false)

  ruby.add_matcher(:standard,
                   /((^(module|class|def))|#{pre_keyword_boundary}do)\b/,
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
                   /(((^|;\s*)(if|unless))|#{pre_keyword_boundary}(then|elsif|else))\b/,
                   /#{pre_keyword_boundary}(then|elsif|else|end)\b/,
                   :nest_except => [:case])

  ruby.add_matcher(:case,
                   /#{pre_keyword_boundary}case\b/,
                   /(^|;\s*)end\b/)

  ruby.add_matcher(:inner_case,
                   /((^|;\s*)(when|else)|#{pre_keyword_boundary}then)\b/,
                   /((^|;\s*)(when|else)|#{pre_keyword_boundary}then)\b/,
                   :nest_only => [:case],
                   :end => :implicit,
                   :end_can_also_be_start => true)

  # TODO: Improve the check that this is not a block with arguments. Will
  # currently match any bracket followed by spaces and |.
  bracket_indent_end_line_proc = Proc.new { |block| !block.after_match.empty? && !block.after_match.match(/^\|/) }
  bracket_indent_size_proc = Proc.new do |block|
    if bracket_indent_end_line_proc.call(block)
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
                   /(^|((,|=|~)\s*))\//, # Try to distinguish it from division sign
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
                   /(,|\.|\+|-|=\>|=|&&|\|\||\\|==|\s\?|:)(\s*)?(#.*)?$/,
                   /(^|(,|\.|\+|-|=\>|=|&&|\|\||\\|==|\s\?|:)(\s*)?)(#.*)?$/,
                   :indent_end_line => true,
                   :negate_ends_match => true,
                   :nest_except => [:continuing_line, :curly_bracket, :round_bracket, :square_bracket])

end
