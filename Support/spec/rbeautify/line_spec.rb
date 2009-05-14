require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RBeautify::Line do

  describe '#format' do

    before(:each) do
      @language = mock(RBeautify::Language)
    end

    it 'should just strip with empty stack' do
      RBeautify::BlockMatcher.stub!(:calculate_stack => [])
      RBeautify::Line.new(@language, ' a = 3 ').format.should == "a = 3"
    end

    it 'should indent with existing indent' do
      current_block = mock(RBeautify::Block, :indent_size => 2, :format? => true)
      RBeautify::BlockMatcher.stub!(:calculate_stack => [current_block])
      RBeautify::Line.new(@language, ' a = 3 ', [current_block]).format.should == '  a = 3'
    end

    it 'leave empty lines blank' do
      current_block = mock(RBeautify::Block, :format? => true)
      RBeautify::Line.new(@language, '    ', [current_block]).format.should == ''
    end

    it 'should remove indent with match to end of block' do
      current_block = mock(RBeautify::Block, :indent_size => 2, :format? => true, :indent_end_line? => false)
      RBeautify::BlockMatcher.stub!(:calculate_stack => [])
      RBeautify::Line.new(@language, '  end ', [current_block]).format.should == 'end'
    end

    it 'should not remove indent with match to end of block if indent_end_line? is true' do
      current_block = mock(RBeautify::Block, :indent_size => 2, :format? => true, :indent_end_line? => true)
      RBeautify::BlockMatcher.stub!(:calculate_stack => [])
      RBeautify::Line.new(@language, '  foo ', [current_block]).format.should == '  foo'
    end

    it 'should leave indent with match to end of block (but no format)' do
      current_block = mock(RBeautify::Block, :format? => false)
      RBeautify::BlockMatcher.stub!(:calculate_stack => [])
      RBeautify::Line.new(@language, '  "', [current_block]).format.should == '  "'
    end

    it 'should leave indent at old stack level with match of new block' do
      current_block = mock(RBeautify::Block, :indent_size => 2, :format? => true)
      new_block = mock(RBeautify::Block, :format? => true)
      RBeautify::BlockMatcher.stub!(:calculate_stack => [current_block, new_block])
      RBeautify::Line.new(@language, 'class Foo', [current_block]).format.should == '  class Foo'
    end

    it 'should not change when format is false' do
      current_block = mock(RBeautify::Block, :format? => false)
      RBeautify::BlockMatcher.stub!(:calculate_stack => [current_block])
      RBeautify::Line.new(@language, ' some content after program has finished. ', [current_block]).format.should ==
        " some content after program has finished. "
    end

    it 'should remove indent if a block ends and starts' do
      current_block = mock(RBeautify::Block, :format? => true)
      new_block = mock(RBeautify::Block, :indent_size => 2, :format? => true)
      RBeautify::BlockMatcher.stub!(:calculate_stack => [new_block])
      RBeautify::Line.new(@language, ' else ', [current_block]).format.should == 'else'
    end

  end

  describe '#stack' do

    it 'should return calculated stack' do
      RBeautify::BlockMatcher.stub!(:calculate_stack => [])
      RBeautify::Line.new(@language, ' a = 3 ', []).stack.should == []
    end

  end

  describe 'private methods' do

    describe '#stripped' do
      it { RBeautify::Line.new(@language, '     def foo # some comment     ').send(:stripped).should == 'def foo # some comment' }
      it { RBeautify::Line.new(@language, '     "some string"     ').send(:stripped).should == '"some string"' }
    end

  end

end
