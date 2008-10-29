require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/rbeautify.rb'

describe RBeautify do

  describe 'when' do
    
    it 'should not indent case statement' do      
      input = <<TEXT
case foo
when 1
bar = 'some string'
when 2
bar = 'some other string'
end
TEXT
      output = <<TEXT
case foo
when 1
  bar = 'some string'
when 2
  bar = 'some other string'
end
TEXT
      RBeautify.beautify_string(input).should == output
    end

  end
  
  describe 'comments' do
    
    it "should ignore code after end of line comment" do
      input = <<TEXT
def method_containing_end_of_line_comment
a = b # Comment containing do
end
TEXT
      output =  <<TEXT
def method_containing_end_of_line_comment
  a = b # Comment containing do
end
TEXT
      RBeautify.beautify_string(input).should == output
    end
    
    it "should not indent multineline comment" do
      input = <<TEXT
=begin
Comment
=end
foo
TEXT
      RBeautify.beautify_string(input).should == input
    end
  
  end

  describe 'multiline code' do
    
    it "should indent lines after first of multiline code" do
      input = <<TEXT
def method_with_multiline_method_call
multiline_method_call first_arg, \\
second_arg, \\
third_arg
end
TEXT
      output = <<TEXT
def method_with_multiline_method_call
  multiline_method_call first_arg, \\
    second_arg, \\
    third_arg
end
TEXT
      RBeautify.beautify_string(input).should == output
    end
    
    it "should indent method call with bracketed multiline arguments" do 
      input = <<TEXT
def method_with_multiline_method_call
multiline_method_call(first_arg,
second_arg,
third_arg,
fourth_arg
)
end
TEXT
      output = <<TEXT
def method_with_multiline_method_call
  multiline_method_call(first_arg,
    second_arg,
    third_arg,
    fourth_arg
  )
end
TEXT
      RBeautify.beautify_string(input).should == output
    end
    
    it "should indent method call with multiline arguments (implicit brackets)" do 
      input = <<TEXT
def method_with_multiline_method_call
multiline_method_call first_arg,
second_arg,
# Comment in the middle of all this
third_arg

another_method_call
end
TEXT
      output = <<TEXT
def method_with_multiline_method_call
  multiline_method_call first_arg,
    second_arg,
    # Comment in the middle of all this
    third_arg

  another_method_call
end
TEXT
      RBeautify.beautify_string(input).should == output
    end

    it "should indent multiline method call chains" do 
      input = <<TEXT
def method_with_multiline_method_call_chain
multiline_method_call.
foo.
bar

another_method_call
end
TEXT
      output = <<TEXT
def method_with_multiline_method_call_chain
  multiline_method_call.
    foo.
    bar

  another_method_call
end
TEXT
      RBeautify.beautify_string(input).should == output
    end

    it 'should handle multiline code with escaped quotes in strings' do
      input = <<TEXT
def method_containing_multiline_code_with_strings
a = "foo \\"\#{method}\\">" +
"bar"
end
TEXT
      output =  <<TEXT
def method_containing_multiline_code_with_strings
  a = "foo \\"\#{method}\\">" +
    "bar"
end
TEXT
      RBeautify.beautify_string(input).should == output
    end
  end
      
  describe 'multiline strings' do

    it "should not change the indentation of multiline strings" do
      pending 'implementation'
      input = <<TEXT
def method_containing_long_string
a = <<STRING
Some text across multiple lines
And another line
STRING
b = 5
end
TEXT
      output =  <<TEXT
def method_containing_long_string
  a = <<STRING
Some text across multiple lines
And another line
STRING
  b = 5
end
TEXT
      RBeautify.beautify_string(input).should == output
    end

  end

  describe RBeautify::RubyLine do
    
    it { RBeautify::RubyLine.new('def foo', nil).send(:indent?).should be_true }
    it { RBeautify::RubyLine.new('def foo', nil).send(:indent_relevant_content).should == 'def foo' }
    it { RBeautify::RubyLine.new('def foo', nil).send(:stripped).should == 'def foo' }

    describe 'has_following_line?' do
      it { RBeautify::RubyLine.new('foo :bar,', nil).send(:has_following_line?).should_not be_nil }
      it { RBeautify::RubyLine.new('foo.', nil).send(:has_following_line?).should_not be_nil }
      it { RBeautify::RubyLine.new('puts foo +', nil).send(:has_following_line?).should_not be_nil }
      it { RBeautify::RubyLine.new('foo :bar =>', nil).send(:has_following_line?).should_not be_nil }
    end
  end
end
