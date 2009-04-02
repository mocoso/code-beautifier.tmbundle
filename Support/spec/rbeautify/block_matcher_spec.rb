require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RBeautify::BlockMatcher do

  describe '.calculate_stack' do

    it 'should not match de' do
      RBeautify::BlockMatcher.calculate_stack('foo').should be_empty
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
      RBeautify::BlockMatcher.calculate_stack('def foo(bar = {})').first.block_matcher.should == RBeautify::BlockMatcher::STANDARD_MATCHER
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
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.after_start_match('class Foo').should == ' Foo' }
      it { @matcher.after_start_match('module Foo').should == ' Foo' }
      it { @matcher.after_start_match('def foo()').should == ' foo()' }
      it { @matcher.after_start_match('class Foo; end').should == ' Foo; end' }
      it { @matcher.after_start_match('end').should be_nil }

      it { @matcher.after_end_match('end', [@current_block]).should == '' }
      it { @matcher.after_end_match('; end', [@current_block]).should == '' }
      it { @matcher.after_end_match('rescue', [@current_block]).should == '' }
      it { @matcher.after_end_match('ensure', [@current_block]).should == '' }
      it { @matcher.after_end_match('}', [@current_block]).should be_nil }
      it { @matcher.after_end_match('foo end', [@current_block]).should be_nil }

    end

    describe 'IF_AND_CASE_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::IF_AND_CASE_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.after_start_match('if foo').should == ' foo' }
      it { @matcher.after_start_match('case foo').should == ' foo' }
      it { @matcher.after_start_match('when foo').should == ' foo' }
      it { @matcher.after_start_match('then foo = bar').should == ' foo = bar' }

      it { @matcher.after_end_match('end', [@current_block]).should == '' }
      it { @matcher.after_end_match('when', [@current_block]).should == '' }
      it { @matcher.after_end_match('then', [@current_block]).should == '' }
      it { @matcher.after_end_match('else', [@current_block]).should == '' }

      it { @matcher.after_end_match('a = 3', [@current_block]).should be_nil }

    end

    describe 'CURLY_BRACKET_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::CURLY_BRACKET_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.after_start_match('{').should == '' }
      it { @matcher.after_start_match('end').should be_nil }

      it { @matcher.after_end_match('}', [@current_block]).should == '' }
      it { @matcher.after_end_match('end', [@current_block]).should be_nil }

    end

    describe 'DOUBLE_QUOTE_STRING_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::DOUBLE_QUOTE_STRING_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.after_start_match('a = "foo').should == 'foo' }
      it { @matcher.after_start_match('a = 2').should be_nil }

      it { @matcher.after_end_match(' bar"', [@current_block]).should == '' }
      it { @matcher.after_end_match('a = 2', [@current_block]).should be_nil }

    end

    describe 'MULTILINE_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::MULTILINE_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.after_start_match('a = 3 &&').should == '' }
      it { @matcher.after_start_match('a = 3 ||').should == '' }
      it { @matcher.after_start_match('a = 3 +').should == '' }
      it { @matcher.after_start_match('a = 3 -').should == '' }
      it { @matcher.after_start_match('foo :bar,').should == '' }
      it { @matcher.after_start_match('a \\').should == '' }
      it { @matcher.after_start_match('a = 3').should be_nil }

      it { @matcher.after_end_match('a = 3', [@current_block]).should == 'a = 3' }
      it { @matcher.after_end_match('a = 3 &&', [@current_block]).should be_nil }
      it { @matcher.after_end_match('a = 3 +', [@current_block]).should be_nil }
      it { @matcher.after_end_match('foo :bar,', [@current_block]).should be_nil }

    end

    describe 'IMPLICIT_END_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::IMPLICIT_END_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.after_start_match('private').should == ''}
      it { @matcher.after_start_match('protected').should == '' }
      it { @matcher.after_start_match('a = 3').should be_nil }

      it { @matcher.after_end_match('protected', [@current_block]).should == '' }
      it { @matcher.after_end_match('a = 3', [@current_block]).should be_nil }

      it 'should return both if implicit end from next block in stack' do
        surrounding_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
        @matcher.after_end_match('end', [surrounding_block, @current_block]).should == ''
      end

      it 'should return none if no implicit end from next block in stack' do
        surrounding_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
        @matcher.after_end_match('a = 3', [surrounding_block, @current_block]).should be_nil
      end

    end
    
    describe 'ROUND_BRACKET_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::ROUND_BRACKET_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.after_start_match('()').should == ')'}
      it { @matcher.after_start_match('anything else').should be_nil }

      it { @matcher.after_end_match(')', [@current_block]).should == '' }
      it { @matcher.after_end_match('a = 3', [@current_block]).should be_nil }

    end

  end

end
