require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RBeautify::BlockMatcher do

  describe '#block' do

    before(:each) do
      @matcher = RBeautify::BlockMatcher.new(/foo/, /bar/)
    end

    it 'should return new block if matches' do
      block = mock('block')
      RBeautify::Block.should_receive(:new).with(@matcher).and_return(block)
      @matcher.block('foo and some other stuff', nil).should == block
    end

    it 'should return nil if no match' do
      @matcher.block('some other string', nil).should be_nil
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

      it { @matcher.block('class Foo', nil).should_not be_nil }
      it { @matcher.block('module Foo', nil).should_not be_nil }
      it { @matcher.block('def foo()', nil).should_not be_nil }
      it { @matcher.block('end', nil).should be_nil }
      it { @matcher.block('class Foo; end', nil).should be_nil }

      it { @matcher.ended_blocks('end', @current_block, []).should == [@current_block] }
      it { @matcher.ended_blocks('rescue', @current_block, []).should == [@current_block] }
      it { @matcher.ended_blocks('ensure', @current_block, []).should == [@current_block] }
      it { @matcher.ended_blocks('}', @current_block, []).should == [] }

    end

    describe 'CURLY_BRACKET_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::CURLY_BRACKET_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.block('{', nil).should_not be_nil }
      it { @matcher.block('end', nil).should be_nil }

      it { @matcher.ended_blocks('}', @current_block, []).should == [@current_block] }
      it { @matcher.ended_blocks('end', @current_block, []).should == [] }

    end

    describe 'MULTILINE_STRING_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::MULTILINE_STRING_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.block('a = "', nil).should_not be_nil }
      it { @matcher.block('a = 2', nil).should be_nil }

      it { @matcher.ended_blocks('"', @current_block, []).should == [@current_block] }
      it { @matcher.ended_blocks('a = 2', @current_block, []).should == [] }

    end

    describe 'MULTILINE_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::MULTILINE_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.block('a = 3 &&', nil).should_not be_nil }
      it { @matcher.block('a = 3 ||', nil).should_not be_nil }
      it { @matcher.block('a = 3 +', nil).should_not be_nil }
      it { @matcher.block('a = 3 -', nil).should_not be_nil }
      it { @matcher.block('foo :bar,', nil).should_not be_nil }
      it { @matcher.block('a \\', nil).should_not be_nil }
      it { @matcher.block('a = 3', nil).should be_nil }

      it { @matcher.block('foo :bar,', mock('block', :block_matcher => @matcher, :format? => true)).should be_nil }

      it { @matcher.ended_blocks('a = 3', @current_block, []).should == [@current_block] }
      it { @matcher.ended_blocks('a = 3 &&', @current_block, []).should == [] }
      it { @matcher.ended_blocks('a = 3 +', @current_block, []).should == [] }
      it { @matcher.ended_blocks('foo :bar,', @current_block, []).should == [] }

    end

    describe 'IMPLICIT_END_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::IMPLICIT_END_MATCHER
        @current_block = RBeautify::Block.new(@matcher)
      end

      it { @matcher.block('private', nil).should_not be_nil }
      it { @matcher.block('protected', nil).should_not be_nil }
      it { @matcher.block('a = 3', nil).should be_nil }

      it { @matcher.ended_blocks('protected', @current_block, []).should == [@current_block] }
      it { @matcher.ended_blocks('a = 3', @current_block, []).should == [] }

      it 'should return both if implicit end from next block in stack' do
        surrounding_block = mock('block')
        surrounding_block.stub!(:ended_blocks => [surrounding_block])
        @matcher.ended_blocks('end', @current_block, [surrounding_block]).should == [@current_block, surrounding_block]
      end

      it 'should return none if no implicit end from next block in stack' do
        surrounding_block = mock('block', :ended_blocks => [])
        @matcher.ended_blocks('a = 3', @current_block, [surrounding_block]).should == []
      end

    end

  end

end
