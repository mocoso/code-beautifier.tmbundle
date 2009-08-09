# RSpec support
begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end
begin
  require 'spec/rake/spectask'
rescue LoadError
  puts <<-EOS
  To use rspec for testing you must install rspec gem:
    gem install rspec
  EOS
  exit(0)
end

spec_common = Proc.new do |t|
  t.spec_files = FileList['Support/spec/**/*/*_spec.rb']
end

task :default => :spec

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  spec_common.call(t)
end

namespace :spec do
  desc "Run all specs in spec directory with RCov (excluding plugin specs)"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    spec_common.call(t)
    t.rcov = true
    t.rcov_opts = ['-x', 'Support/spec/', '-T']
  end
end
