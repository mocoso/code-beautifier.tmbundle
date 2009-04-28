require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RBeautify::Line do

  describe '#format' do

    it 'should just strip with empty stack' do
      RBeautify::Line.new(' a = 3 ').format.should == "a = 3"
    end

    it 'should indent with existing indent' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new(' a = 3 ', [current_block]).format.should == '  a = 3'
    end

    it 'leave empty lines blank' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new('    ', [current_block]).format.should == ''
    end

    it 'should remove indent with match to end of block' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new('  end ', [current_block]).format.should == 'end'
    end

    it 'should remove double indent with match to end of block when end is implicit' do
      surrounding_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::IMPLICIT_END_MATCHER)
      RBeautify::Line.new('  end ', [surrounding_block, current_block]).format.should == 'end'
    end

    it 'should leave indent with match to end of block (and indent last line)' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::CONTINUING_LINE_MATCHER)
      RBeautify::Line.new('  foo ', [current_block]).format.should == '  foo'
    end

    it 'should leave indent with match to end of block (but no format)' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::DOUBLE_QUOTE_STRING_MATCHER)
      RBeautify::Line.new('  "', [current_block]).format.should == '  "'
    end

    it 'should leave indent at old stack level with match of new block' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new('class Foo', [current_block]).format.should == '  class Foo'
    end

    it 'should not change when format is false' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::PROGRAM_END_MATCHER)
      RBeautify::Line.new(' some content after program has finished. ', [current_block]).format.should ==
        " some content after program has finished. "
    end

    it 'should remove indent if a block ends and starts' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::IF_AND_CASE_MATCHER)
      RBeautify::Line.new(' else ', [current_block]).format.should == 'else'
    end

  end

  describe '#stack' do

    it 'should keep empty stack if no new block starts' do
      RBeautify::Line.new(' a = 3 ').stack.should == []
    end

    it 'should keep stack if no new block starts or ends' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new(' a = 3 ', [current_block]).stack.should == [current_block]
    end

    it 'should pop block from stack with match to end of block' do
      current_block= RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new('  end ', [current_block]).stack.should == []
    end

    it 'should pop block from stack with match to end of block when format is false' do
      current_block= RBeautify::Block.new(RBeautify::BlockMatcher::DOUBLE_QUOTE_STRING_MATCHER)
      RBeautify::Line.new('  foo" ', [current_block]).stack.should == []
    end

    it 'should pop two blocks from stack with match to end of block when end is implicit' do
      surrounding_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::IMPLICIT_END_MATCHER)
      RBeautify::Line.new('  end ', [surrounding_block, current_block]).stack.should == []
    end

    describe 'add one to stack' do

      it 'should add for "class Foo"' do
        current_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
        RBeautify::Line.new('class Foo', [current_block]).stack.size.should == 2
        RBeautify::Line.new('class Foo', [current_block]).stack.first.should == current_block
        RBeautify::Line.new('class Foo', [current_block]).stack.last.block_matcher.should == RBeautify::BlockMatcher::STANDARD_MATCHER
      end

      it 'should add for "def foo(bar = {})"' do
        current_block = RBeautify::Block.new(RBeautify::BlockMatcher::STANDARD_MATCHER)
        RBeautify::Line.new('def foo(bar = {})', [current_block]).stack.size.should == 2
        RBeautify::Line.new('def foo(bar = {})', [current_block]).stack.first.should == current_block
        RBeautify::Line.new('def foo(bar = {})', [current_block]).stack.last.block_matcher.should == RBeautify::BlockMatcher::STANDARD_MATCHER
      end

    end

    it 'should add and remove if a block ends and starts' do
      current_block = RBeautify::Block.new(RBeautify::BlockMatcher::IF_AND_CASE_MATCHER)
      RBeautify::Line.new(' else ', [current_block]).stack.size.should == 1
      RBeautify::Line.new(' else ', [current_block]).stack.last.block_matcher.should == RBeautify::BlockMatcher::STANDARD_MATCHER
    end

    it 'should keep stack the same if block ends and starts on same line' do
      RBeautify::Line.new('while (foo = bar); end ', []).stack.should be_empty
    end

  end

  describe 'private methods' do

    describe '#indent_relevant_content' do
      it { RBeautify::Line.new('     def foo \\').send(:indent_relevant_content).should == 'def foo \\' }
      it { RBeautify::Line.new('     def foo # some comment').send(:indent_relevant_content).should == 'def foo' }
      it { RBeautify::Line.new('     a = 1    ').send(:indent_relevant_content).should == 'a = 1' }
      it { RBeautify::Line.new("     describe '#foo'   ").send(:indent_relevant_content).should == "describe '#foo'" }
    end

    describe '#stripped' do
      it { RBeautify::Line.new('     def foo # some comment     ').send(:stripped).should == 'def foo # some comment' }
      it { RBeautify::Line.new('     "some string"     ').send(:stripped).should == '"some string"' }
    end

  end

end
