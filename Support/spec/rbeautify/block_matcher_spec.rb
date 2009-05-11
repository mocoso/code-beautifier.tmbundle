require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RBeautify::BlockMatcher do

  describe '.calculate_stack' do

    it 'should not match de' do
      RBeautify::BlockMatcher.calculate_stack('de foo').should be_empty
    end

    it 'should match def' do
      RBeautify::BlockMatcher.calculate_stack('def foo').size.should == 1
    end

    it 'should match nested blocks' do
      RBeautify::BlockMatcher.calculate_stack('if {').size.should == 2
    end

    it 'should match nested blocks (taking into account ends)' do
      RBeautify::BlockMatcher.calculate_stack('if {}').size.should == 1
    end

    it 'should match nested blocks (taking into account ends)' do
      RBeautify::BlockMatcher.calculate_stack('def foo(bar = {})').size.should == 1
      RBeautify::BlockMatcher.calculate_stack('def foo(bar = {})').first.block_matcher.should ==
        RBeautify::BlockMatcher::STANDARD_MATCHER
    end

    it 'should not change if no started or ended blocks' do
      current_stack = [RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER, 0, 'def', ' foo')]
      RBeautify::BlockMatcher.calculate_stack('a = 3', current_stack).should == current_stack
    end

    it 'should remove block if top of stack ends' do
      current_stack = [
        RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER, 0, 'class', ' Foo'),
        RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER, 0, 'def', ' foo')
      ]
      RBeautify::BlockMatcher.calculate_stack('end', current_stack).should ==
        [RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER, 0, 'class', ' Foo')]
    end

    it 'should remove two blocks if top of stack ends implicitly' do
      current_stack = [
        RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER, 0, 'class', ' Foo'),
        RBeautify::Block.new(RBeautify::BlockMatcher::IMPLICIT_END_MATCHER, 0, 'private', '')
      ]
      RBeautify::BlockMatcher.calculate_stack('end', current_stack).should == []
    end
  end

  describe '#can_nest?' do

    it { RBeautify::BlockMatcher.new(/foo/, /bar/).should be_can_nest(nil) }
    it { RBeautify::BlockMatcher.new(/foo/, /bar/).should be_can_nest(mock('block', :block_matcher => mock('matcher'), :format? => true)) }
    it { RBeautify::BlockMatcher.new(/foo/, /bar/).should_not be_can_nest(mock('block', :block_matcher => mock('matcher'), :format? => false)) }

    it { RBeautify::BlockMatcher.new(/foo/, /bar/, :nest_except => [RBeautify::BlockMatcher::STANDARD_MATCHER]).should be_can_nest(nil) }
    it { RBeautify::BlockMatcher.new(/foo/, /bar/, :nest_except => [RBeautify::BlockMatcher::STANDARD_MATCHER]).should be_can_nest(mock('block', :block_matcher => mock('matcher'), :format? => true)) }
    it { RBeautify::BlockMatcher.new(/foo/, /bar/, :nest_except => [RBeautify::BlockMatcher::STANDARD_MATCHER]).should_not be_can_nest(mock('block', :block_matcher => RBeautify::BlockMatcher::STANDARD_MATCHER, :format? => true)) }

    it { RBeautify::BlockMatcher.new(/foo/, /bar/, :nest_except => [:self]).should be_can_nest(nil) }
    it { RBeautify::BlockMatcher.new(/foo/, /bar/, :nest_except => [:self]).should be_can_nest(mock('block', :block_matcher => RBeautify::BlockMatcher::STANDARD_MATCHER, :format? => true)) }
    it 'should not be able to nest self if options do not allow it' do
      matcher = RBeautify::BlockMatcher.new(/foo/, /bar/, :nest_except => [:self])
      matcher.should_not be_can_nest(mock('block', :block_matcher => matcher, :format? => true))
    end

  end

  describe 'class' do

    describe 'STANDARD_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::STANDARD_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, '', '')
      end

      it { @matcher.block('class Foo; end', 0).should == RBeautify::Block.new(@matcher, 0, 'class', ' Foo; end') }
      it { @matcher.block('module Foo', 0).should == RBeautify::Block.new(@matcher, 0, 'module', ' Foo') }
      it { @matcher.block('def foo()', 0).should == RBeautify::Block.new(@matcher, 0, 'def', ' foo()') }
      it { @matcher.block('end Foo', 0).should be_nil }

      it { @matcher.end_match('end', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('; end', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('rescue', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('ensure', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('}', [@current_block], 0).should be_nil }
      it { @matcher.end_match('foo end', [@current_block], 0).should be_nil }

    end

    describe 'IF_AND_CASE_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::IF_AND_CASE_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, 'if', ' foo')
      end

      it { @matcher.block('if foo', 0).should == RBeautify::Block.new(@matcher, 0, 'if', ' foo') }
      it { @matcher.block('case foo', 0).should == RBeautify::Block.new(@matcher, 0, 'case', ' foo') }
      it { @matcher.block('when foo', 0).should == RBeautify::Block.new(@matcher, 0, 'when', ' foo') }
      it { @matcher.block('then foo = bar', 0).should == RBeautify::Block.new(@matcher, 0, 'then', ' foo = bar') }

      it { @matcher.end_match('end', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('when', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('then', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('else', [@current_block], 0).should == [0, ''] }

      it { @matcher.end_match('a = 3', [@current_block], 0).should be_nil }

    end

    describe 'CURLY_BRACKET_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::CURLY_BRACKET_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, '{', '')
      end

      it { @matcher.block('{', 0).should == RBeautify::Block.new(@matcher, 0, '{', '') }
      it { @matcher.block('end', 0).should be_nil }

      it { @matcher.end_match('}', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('end', [@current_block], 0).should be_nil }

    end

    describe 'DOUBLE_QUOTE_STRING_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::DOUBLE_QUOTE_STRING_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, '"', 'foo"')
      end

      it { @matcher.block('a = "foo"', 0).should == RBeautify::Block.new(@matcher, 4, '"', 'foo"') }
      it { @matcher.block('a = 2', 0).should be_nil }

      it { @matcher.end_match(' bar"', [@current_block], 0).should == [4, ''] }
      it { @matcher.end_match(' " + bar + "', [@current_block], 0).should == [1, ' + bar + "'] }
      it { @matcher.end_match('\\\\"', [@current_block], 0).should == [2, ''] }
      it { @matcher.end_match('\\" still within string"', [@current_block], 0).should == [20, ''] }
      it { @matcher.end_match('a = 2', [@current_block], 0).should be_nil }
      it { @matcher.end_match('\\"', [@current_block], 0).should be_nil }
      it { @matcher.end_match('\\\\\\"', [@current_block], 0).should be_nil }

    end

    describe 'SINGLE_QUOTE_STRING_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::SINGLE_QUOTE_STRING_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, "'", "foo'")
      end

      it { @matcher.block("describe '#foo?' do", 0).should == RBeautify::Block.new(@matcher, 9, "'", "#foo?' do") }
      it { @matcher.block('a = 2', 0).should be_nil }

      it { @matcher.end_match("#foo?' do", [@current_block], 9).should == [14, ' do'] }
      it { @matcher.end_match('a = 2', [@current_block], 0).should be_nil }

    end

    describe 'CONTINUING_LINE_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::CONTINUING_LINE_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 8, ',', '')
      end

      it { @matcher.block('foo :bar,', 0).should == RBeautify::Block.new(@matcher, 8, ',', '') }
      it { @matcher.block('a = 3 &&', 0).should == RBeautify::Block.new(@matcher, 6, '&&', '') }
      it { @matcher.block('a = 3 ||', 0).should == RBeautify::Block.new(@matcher, 6, '&&', '') }
      it { @matcher.block('a = 3 +', 0).should == RBeautify::Block.new(@matcher, 6, '&&', '') }
      it { @matcher.block('a = 3 -', 0).should == RBeautify::Block.new(@matcher, 6, '&&', '') }
      it { @matcher.block("a \\", 0).should == RBeautify::Block.new(@matcher, 2, '\\', '') }
      it { @matcher.block('a ?', 0).should == RBeautify::Block.new(@matcher, 1, ' ?', '')  }
      it { @matcher.block('a ? # some comment', 0).should == RBeautify::Block.new(@matcher, 1, ' ? # some comment', '') }
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

    describe 'IMPLICIT_END_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::IMPLICIT_END_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, '', '')
      end

      it { @matcher.block('private', 0).should == RBeautify::Block.new(@matcher, 0, 'private', '') }
      it { @matcher.block('protected', 0).should == RBeautify::Block.new(@matcher, 0, 'protected', '') }
      it { @matcher.block('a = 3', 0).should be_nil }

      it { @matcher.end_match('protected', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('protected # some comment', [@current_block], 0).should == [0, ''] }
      it { @matcher.end_match('a = 3', [@current_block], 0).should be_nil }

      it 'should return both if implicit end from next block in stack' do
        surrounding_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER, 0, 'def', ' foo')
        @matcher.end_match('end', [surrounding_block, @current_block], 0).should == [0, '']
      end

      it 'should return none if no implicit end from next block in stack' do
        surrounding_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER, 0, 'def', ' foo')
        @matcher.end_match('a = 3', [surrounding_block, @current_block], 0).should be_nil
      end

    end

    describe 'ROUND_BRACKET_MATCHER' do
      before(:each) do
        @matcher = RBeautify::BlockMatcher::ROUND_BRACKET_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, '(', '')
      end

      it { @matcher.block('a = (foo,', 0).should == RBeautify::Block.new(@matcher, 4, 'a = (', 'foo,') }
      it { @matcher.block('anything else', 0).should be_nil }

      it { @matcher.end_match('foo)', [@current_block], 0).should == [3, ''] }
      it { @matcher.end_match('a = 3', [@current_block], 0).should be_nil }

    end

    describe 'COMMENT_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::COMMENT_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 8, '#', ' comment')
      end

      it { @matcher.block('anything # comment', 0).should == RBeautify::Block.new(@matcher, 8, '#', ' comment') }
      it { @matcher.block('#', 0).should == RBeautify::Block.new(@matcher, 0, '#', '') }
      it { @matcher.block('anything else', 0).should be_nil }

      it { @matcher.end_match('anything', [@current_block], 0).should == [8, ''] }
      it { @matcher.end_match('', [@current_block], 0).should == [0, ''] }

    end

    describe 'REGEX_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::REGEX_MATCHER
        @current_block = RBeautify::Block.new(@matcher, 0, '/', 'foo/')
      end

      it { @matcher.block('/foo/', 0).should == RBeautify::Block.new(@matcher, 0, '/', 'foo/') }
      it { @matcher.block(', /foo/', 0).should == RBeautify::Block.new(@matcher, 0, ', /', 'foo/') }
      it { @matcher.block('1/2', 0).should be_nil }
      it { @matcher.block('anything else', 0).should be_nil }

      it { @matcher.end_match('foo/', [@current_block], 0).should == [3, ''] }
      it { @matcher.end_match('', [@current_block], 0).should be_nil }

    end

  end

end
