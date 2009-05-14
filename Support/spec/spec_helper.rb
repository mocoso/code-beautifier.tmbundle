require 'rubygems'
require 'spec'
require 'ruby-debug'
require File.dirname(__FILE__) + '/../lib/rbeautify.rb'

module RBeautifyMatchers
  # Adds more descriptive failure messages to the dynamic be_valid matcher
  class BeBlockLike #:nodoc:
    def initialize(block_matcher_name, start_offset, start_match, after_start_match)
      # triggers the standard Spec::Matchers::Be magic, as if the original Spec::Matchers#method_missing had fired
      @block_matcher_name = block_matcher_name
      @start_offset = start_offset
      @start_match = start_match
      @after_start_match = after_start_match
    end

    def matches?(target_block)
      @target_block = target_block
      return !target_block.nil? &&
        (expected_string == got_string)
    end

    def failure_message
      "expected\n#{expected_string} but got\n#{got_string}"
    end

    def negative_failure_message
      "expected to be different from #{expected_string}"
    end

    def expected_string
      "name: #{@block_matcher_name}, start_offset: #{@start_offset}, start_match: '#{@start_match}', after_start_match: '#{@after_start_match}'"
    end

    def got_string
      "name: #{@target_block.block_matcher.name}, start_offset: #{@target_block.start_offset}, start_match: '#{@target_block.start_match}', after_start_match: '#{@target_block.after_start_match}'"
    end

    def description
      "block with"
    end

  end

  def be_block_like(block_matcher, start_offset, start_match, after_start_match)
    BeBlockLike.new(block_matcher, start_offset, start_match, after_start_match)
  end
end

Spec::Runner.configure do |config|
  config.include(RBeautifyMatchers)
end

def run_fixtures_for_language(language)

  fixtures = YAML.load_file(File.dirname(__FILE__) + "/fixtures/#{language}.yml")

  describe language do
    fixtures.each do |fixture|
      it "should #{fixture['name']}" do
        if fixture['pending']
          pending fixture['pending']
        end
        input = fixture['input']
        output = fixture['output'] || input
        RBeautify.beautify_string(language, input).should == output
      end
    end
  end

end
