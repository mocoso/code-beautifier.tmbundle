require 'spec_helper.rb'

describe RBeautify do

  describe 'if else end' do

    it 'should indent if else end statement' do
      input = "
if foo
bar = true
else
bar = false
end
"
      output = "
if foo
  bar = true
else
  bar = false
end
"

      RBeautify.beautify_string(input).should == output
    end

  end

  describe 'when' do

    it 'should not indent case statement' do
      input = "
case foo
when 1
bar = 'some string'
when 2
bar = 'some other string'
when 3 then bar = '3'
else
bar = '4'
end
"
      output = "
case foo
when 1
  bar = 'some string'
when 2
  bar = 'some other string'
when 3 then bar = '3'
else
  bar = '4'
end
"
      RBeautify.beautify_string(input).should == output
    end

  end

  describe 'comments' do

    it "should ignore code after end of line comment" do
      input = "
def method_containing_end_of_line_comment
a = b # Comment containing do
end
"
      output =  "
def method_containing_end_of_line_comment
  a = b # Comment containing do
end
"
      RBeautify.beautify_string(input).should == output
    end

    it "should not indent multineline comment" do
      input = "
=begin
Comment
=end
foo
"

      RBeautify.beautify_string(input).should == input
    end

  end

  describe 'multiline code' do

    it "should indent lines after first of multiline code" do
      input = "
def method_with_multiline_method_call
multiline_method_call first_arg, \\
second_arg, \\
third_arg
end
"
      output = "
def method_with_multiline_method_call
  multiline_method_call first_arg, \\
    second_arg, \\
    third_arg
end
"

      RBeautify.beautify_string(input).should == output
    end

    it "should indent method call with bracketed multiline arguments" do
      input = "
def method_with_multiline_method_call
multiline_method_call(first_arg,
second_arg,
third_arg,
fourth_arg
)
end
"
      output = "
def method_with_multiline_method_call
  multiline_method_call(first_arg,
    second_arg,
    third_arg,
    fourth_arg
  )
end
"
      RBeautify.beautify_string(input).should == output
    end

    it "should indent method call with multiline arguments (implicit brackets)" do
      input = "
def method_with_multiline_method_call
multiline_method_call first_arg,
second_arg,
# Comment in the middle of all this
third_arg

another_method_call
end
"
      output = "
def method_with_multiline_method_call
  multiline_method_call first_arg,
    second_arg,
    # Comment in the middle of all this
    third_arg

  another_method_call
end
"
      RBeautify.beautify_string(input).should == output
    end

    it "should indent multiline method call chains" do
      input = "
def method_with_multiline_method_call_chain
multiline_method_call.
foo.
bar

another_method_call
end
"
      output = "
def method_with_multiline_method_call_chain
  multiline_method_call.
    foo.
    bar

  another_method_call
end
"
      RBeautify.beautify_string(input).should == output
    end

    it 'should handle multiline code with escaped quotes in strings' do
      input = "
def method_containing_multiline_code_with_strings
a = \"foo \#{method}\" +
\"bar\"
end
"
      output = "
def method_containing_multiline_code_with_strings
  a = \"foo \#{method}\" +
    \"bar\"
end
"
      RBeautify.beautify_string(input).should == output
    end
  end

  describe 'multiline strings' do

    it "should not change the indentation of multiline strings" do
      input = "
def method_containing_long_string
a = \"
Some text across multiple lines
And another line
\"
b = 5
end
"
      output = "
def method_containing_long_string
  a = \"
Some text across multiple lines
And another line
\"
  b = 5
end
"
      RBeautify.beautify_string(input).should == output
    end

  end


  describe 'implicitly ended blocks' do

    it "should end indentation of implicit blocks when another implicit block starts or when surrounding block ends" do
      input = "
class Foo
private
def method
b = 5
end
protected
def another_method
c = 5
end
end
"
      output = "
class Foo
  private
    def method
      b = 5
    end
  protected
    def another_method
      c = 5
    end
end
"
      RBeautify.beautify_string(input).should == output
    end

  end
end
