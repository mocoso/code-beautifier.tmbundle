require 'spec_helper.rb'

fixtures = YAML.load_file(File.dirname(__FILE__) + '/fixtures.yml')

describe RBeautify do
  fixtures.each do |fixture|
    it "should #{fixture['name']}" do
      if fixture['pending']
        pending fixture['pending']
      end
      input = fixture['input']
      output = fixture['output'] || input
      RBeautify.beautify_string(input).should == output
    end
  end
end
