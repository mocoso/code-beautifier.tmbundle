require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RBeautify::BlockMatcher do

  describe '.calculate_stack' do
    before(:each) do
      @ruby = RBeautify::Language.language(:ruby)
    end

    it 'should not match de' do
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'de foo').should be_empty
    end

    it 'should match def' do
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'def foo').size.should == 1
    end

    it 'should match nested blocks' do
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'if {').size.should == 2
    end

    it 'should match nested blocks (taking into account ends)' do
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'if {}').size.should == 1
    end

    it 'should match nested blocks (taking into account ends)' do
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'def foo(bar = {})').size.should == 1
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'def foo(bar = {})').first.block_matcher.should ==
        @ruby.matcher(:standard)
    end

    it 'should not change if no started or ended blocks' do
      current_stack = [RBeautify::Block.new(@ruby.matcher(:standard), 0, 'def', ' foo')]
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'a = 3', current_stack).should == current_stack
    end

    it 'should remove block if top of stack ends' do
      surrounding_block = RBeautify::Block.new(@ruby.matcher(:standard), 0, 'class', ' Foo')
      current_stack = [
        surrounding_block,
        RBeautify::Block.new(@ruby.matcher(:standard), 0, 'def', ' foo')
      ]
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'end', current_stack, 0).should == [surrounding_block]
    end

    it 'should remove two blocks if top of stack ends implicitly' do
      current_stack = [
        RBeautify::Block.new(@ruby.matcher(:standard), 0, 'class', ' Foo'),
        RBeautify::Block.new(@ruby.matcher(:implicit_end), 0, 'private', '')
      ]
      RBeautify::BlockMatcher.calculate_stack(@ruby, 'end', current_stack, 0).should == []
    end
  end

  describe '#can_nest?' do
    before(:each) do
      @language = mock(RBeautify::Language)
    end

    it { RBeautify::BlockMatcher.new(@language, :foo, /foo/, /bar/).should be_can_nest(nil) }

    it { RBeautify::BlockMatcher.new(@language, :foo, /foo/, /bar/).should be_can_nest(mock('block', :format? => true)) }

    it { RBeautify::BlockMatcher.new(@language, :foo, /foo/, /bar/).should_not be_can_nest(mock('block', :format? => false)) }

    it { RBeautify::BlockMatcher.new(@language, :foo, /foo/, /bar/, :nest_except => [:bar]).should be_can_nest(nil) }

    it { RBeautify::BlockMatcher.new(@language, :foo, /foo/, /bar/, :nest_except => [:foo]).should be_can_nest(mock('block', :name => :bar, :format? => true)) }

    it { RBeautify::BlockMatcher.new(@language, :foo, /foo/, /bar/, :nest_except => [:foo]).should_not be_can_nest(mock('block', :name => :bar, :format? => false)) }

    it { RBeautify::BlockMatcher.new(@language, :foo, /foo/, /bar/, :nest_except => [:bar]).should_not be_can_nest(mock('block', :name => :bar, :format? => true)) }
  end

end
