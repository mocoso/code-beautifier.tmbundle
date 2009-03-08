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
      end

      it { @matcher.block('class Foo', nil).should_not be_nil }
      it { @matcher.block('module Foo', nil).should_not be_nil }
      it { @matcher.block('def foo()', nil).should_not be_nil }
      it { @matcher.block('end', nil).should be_nil }

      it { @matcher.should be_end('end', [@matcher]) }
      it { @matcher.should be_end('rescue', [@matcher]) }
      it { @matcher.should_not be_end('}', [@matcher]) }

    end

    describe 'CURLY_BRACKET_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::CURLY_BRACKET_MATCHER
      end

      it { @matcher.block('{', nil).should_not be_nil }
      it { @matcher.block('end', nil).should be_nil }

      it { @matcher.should_not be_end('end', [@matcher]) }
      it { @matcher.should be_end('}', [@matcher]) }

    end

    describe 'MULTILINE_STRING_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::MULTILINE_STRING_MATCHER
      end

      it { @matcher.block('a = "', nil).should_not be_nil }
      it { @matcher.block('a = 2', nil).should be_nil }

      it { @matcher.should be_end('"', [@matcher]) }
      it { @matcher.should_not be_end('a = 2', [@matcher]) }

    end

    describe 'MULTILINE_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::MULTILINE_MATCHER
      end

      it { @matcher.block('a = 3 &&', nil).should_not be_nil }
      it { @matcher.block('a = 3 ||', nil).should_not be_nil }
      it { @matcher.block('a = 3 +', nil).should_not be_nil }
      it { @matcher.block('a = 3 -', nil).should_not be_nil }
      it { @matcher.block('foo :bar,', nil).should_not be_nil }
      it { @matcher.block('a \\', nil).should_not be_nil }
      it { @matcher.block('a = 3', nil).should be_nil }

      it { @matcher.block('foo :bar,', mock('block', :block_matcher => @matcher, :format? => true)).should be_nil }

      it { @matcher.should be_end('a = 3', [@matcher]) }
      it { @matcher.should_not be_end('a = 3 &&', [@matcher]) }
      it { @matcher.should_not be_end('a = 3 +', [@matcher]) }
      it { @matcher.should_not be_end('foo :bar,', [@matcher]) }
    end

    describe 'IMPLICIT_END_MATCHER' do

      before(:each) do
        @matcher = RBeautify::BlockMatcher::IMPLICIT_END_MATCHER
      end

      it { @matcher.block('private', nil).should_not be_nil }
      it { @matcher.block('protected', nil).should_not be_nil }
      it { @matcher.block('a = 3', nil).should be_nil }

      it { @matcher.should_not be_end('a = 3', [@matcher]) }
      it { @matcher.should_not be_end('a = 3', [mock('matcher', :end? => false), @matcher]) }
      it { @matcher.should be_end('a = 3', [mock('matcher', :end? => true), @matcher]) }
    end


  end

end
