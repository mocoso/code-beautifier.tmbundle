require File.dirname(__FILE__) + '/../../spec_helper.rb'

run_fixtures_for_language(:ruby)

describe 'Ruby' do

  describe 'matchers' do
    before(:each) do
      @ruby = RBeautify::Language.language(:ruby)
    end

    describe 'standard' do
      before(:each) do
        @matcher = @ruby.matcher(:standard)
        @current_block = RBeautify::Block.new(@matcher, 0, '', '')
      end

      it { @matcher.block('class Foo; end', 0).should be_block_like(:standard, 0, 'class', ' Foo; end') }
      it { @matcher.block('module Foo', 0).should be_block_like(:standard, 0, 'module', ' Foo') }
      it { @matcher.block('def foo()', 0).should be_block_like(:standard, 0, 'def', ' foo()') }
      it { @matcher.block('end Foo', 0).should be_nil }

      it { @matcher.end_match('end', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('; end', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('rescue', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('ensure', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('}', [@current_block], 0).should be_nil }
      it { @matcher.end_match('foo end', [@current_block], 0).should be_nil }

    end

    describe 'if_and_case' do
      before(:each) do
        @matcher = @ruby.matcher(:if_and_case)
        @current_block = RBeautify::Block.new(@matcher, 0, 'if', ' foo')
      end

      it { @matcher.block('if foo', 0).should be_block_like(:if_and_case, 0, 'if', ' foo') }
      it { @matcher.block('case foo', 0).should be_block_like(:if_and_case, 0, 'case', ' foo') }
      it { @matcher.block('when foo', 0).should be_block_like(:if_and_case, 0, 'when', ' foo') }
      it { @matcher.block('then foo = bar', 0).should be_block_like(:if_and_case, 0, 'then', ' foo = bar') }

      it { @matcher.end_match('end', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('when', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('then', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('else', [@current_block], 0).should == [0, ''] }

      it { @matcher.end_match('a = 3', [@current_block], 0).should be_nil }

    end

    describe 'curly_bracket' do
      before(:each) do
        @matcher = @ruby.matcher(:curly_bracket)
        @current_block = RBeautify::Block.new(@matcher, 0, '{', '')
      end

      it { @matcher.block('{', 0).should be_block_like(:curly_bracket, 0, '{', '') }
      it { @matcher.block('end', 0).should be_nil }

      it { @matcher.end_match('}', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('end', [@current_block], 0).should be_nil }

    end

    describe 'double_quote' do
      before(:each) do
        @matcher = @ruby.matcher(:double_quote)
        @current_block = RBeautify::Block.new(@matcher, 0, '"', 'foo"')
      end

      it { @matcher.block('a = "foo"', 0).should be_block_like(:double_quote, 4, '"', 'foo"') }
      it { @matcher.block('a = 2', 0).should be_nil }

      it { @matcher.end_match(' bar"', [@current_block], 0).should == [4, ''] }
      it { @matcher.end_match(' " + bar + "', [@current_block], 0).should == [1, ' + bar + "'] }
      it { @matcher.end_match('\\\\"', [@current_block], 0).should == [2, ''] }
      it { @matcher.end_match('\\" still within string"', [@current_block], 0).should == [20, ''] }
      it { @matcher.end_match('a = 2', [@current_block], 0).should be_nil }
      it { @matcher.end_match('\\"', [@current_block], 0).should be_nil }
      it { @matcher.end_match('\\\\\\"', [@current_block], 0).should be_nil }

    end

    describe 'single_quote' do
      before(:each) do
        @matcher = @ruby.matcher(:single_quote)
        @current_block = RBeautify::Block.new(@matcher, 0, "'", "foo'")
      end

      it { @matcher.block("describe '#foo?' do", 0).should be_block_like(:single_quote, 9, "'", "#foo?' do") }
      it { @matcher.block('a = 2', 0).should be_nil }

      it { @matcher.end_match("#foo?' do", [@current_block], 9).should == [14, ' do'] }
      it { @matcher.end_match('a = 2', [@current_block], 0).should be_nil }

    end

    describe 'continuing_line' do
      before(:each) do
        @matcher = @ruby.matcher(:continuing_line)
        @current_block = RBeautify::Block.new(@matcher, 8, ',', '')
      end

      it { @matcher.block('foo :bar,', 0).should be_block_like(:continuing_line, 8, ',', '') }
      it { @matcher.block('a = 3 &&', 0).should be_block_like(:continuing_line, 6, '&&', '') }
      it { @matcher.block('a = 3 ||', 0).should be_block_like(:continuing_line, 6, '||', '') }
      it { @matcher.block('a = 3 +', 0).should be_block_like(:continuing_line, 6, '+', '') }
      it { @matcher.block('a = 3 -', 0).should be_block_like(:continuing_line, 6, '-', '') }
      it { @matcher.block("a \\", 0).should be_block_like(:continuing_line, 2, '\\', '') }
      it { @matcher.block('a ?', 0).should be_block_like(:continuing_line, 1, ' ?', '')  }
      it { @matcher.block('a ? # some comment', 0).should be_block_like(:continuing_line, 1, ' ? # some comment', '') }
      it { @matcher.block('a = 3', 0).should be_nil }
      it { @matcher.block('a = foo.bar?', 0).should be_nil }
      it { @matcher.block('# just a comment', 0).should be_nil }

      it { @matcher.end_match('a = 3', [@current_block], 0).should == [0, 'a = 3'] }
      it { @matcher.end_match('foo :bar,', [@current_block], 0).should be_nil }
      it { @matcher.end_match('a = 3 &&', [@current_block], 0).should be_nil }
      it { @matcher.end_match('a = 3 +', [@current_block], 0).should be_nil }
      it { @matcher.end_match("a \\", [@current_block], 0).should be_nil }
      it { @matcher.end_match('# just a comment', [@current_block], 0).should be_nil }
      it { @matcher.end_match('#', [@current_block], 0).should be_nil }

    end

    describe 'implicit_end' do
      before(:each) do
        @matcher = @ruby.matcher(:implicit_end)
        @current_block = RBeautify::Block.new(@matcher, 0, '', '')
      end

      it { @matcher.block('private', 0).should be_block_like(:implicit_end, 0, 'private', '') }
      it { @matcher.block('protected', 0).should be_block_like(:implicit_end, 0, 'protected', '') }
      it { @matcher.block('a = 3', 0).should be_nil }

      it { @matcher.end_match('protected', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('protected # some comment', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('a = 3', [@current_block], 0).should be_nil }

      it 'should return both if implicit end from next block in stack' do
        surrounding_block = RBeautify::Block.new(@ruby.matcher(:standard), 0, 'def', ' foo')
        @matcher.end_match('end', [surrounding_block, @current_block], 0).should == [0, '']
      end

      it 'should return none if no implicit end from next block in stack' do
        surrounding_block = RBeautify::Block.new(@ruby.matcher(:standard), 0, 'def', ' foo')
        @matcher.end_match('a = 3', [surrounding_block, @current_block], 0).should be_nil
      end

    end

    describe 'round_bracket' do
      before(:each) do
        @matcher = @ruby.matcher(:round_bracket)
        @current_block = RBeautify::Block.new(@matcher, 0, '(', '')
      end

      it { @matcher.block('a = (foo,', 0).should be_block_like(:round_bracket, 4, '(', 'foo,') }
      it { @matcher.block('anything else', 0).should be_nil }

      it { @matcher.end_match('foo)', [@current_block], 0).should == [3, ''] }
      it { @matcher.end_match('a = 3', [@current_block], 0).should be_nil }

    end

    describe 'comment' do

      before(:each) do
        @matcher = @ruby.matcher(:comment)
        @current_block = RBeautify::Block.new(@matcher, 8, '#', ' comment')
      end

      it { @matcher.block('anything # comment', 0).should be_block_like(:comment, 8, ' #', ' comment') }
      it { @matcher.block('#', 0).should be_block_like(:comment, 0, '#', '') }
      it { @matcher.block('anything else', 0).should be_nil }

      it { @matcher.end_match('anything', [@current_block], 0).should == [8, ''] }
      it { @matcher.end_match('', [@current_block], 0).should == [0, ''] }

    end

    describe 'regex' do

      before(:each) do
        @matcher = @ruby.matcher(:regex)
        @current_block = RBeautify::Block.new(@matcher, 0, '/', 'foo/')
      end

      it { @matcher.block('/foo/', 0).should be_block_like(:regex, 0, '/', 'foo/') }
      it { @matcher.block(', /foo/', 0).should be_block_like(:regex, 0, ', /', 'foo/') }
      it { @matcher.block('1/2', 0).should be_nil }
      it { @matcher.block('anything else', 0).should be_nil }

      it { @matcher.end_match('foo/', [@current_block], 0).should == [3, ''] }
      it { @matcher.end_match('', [@current_block], 0).should be_nil }

    end

  end

end
