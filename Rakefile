require 'bundler/setup'
require 'rake/testtask'
require 'rspec/core/rake_task'

task :default => [:test]

Rake::TestTask.new(:test) do |tsk|
  tsk.test_files = FileList['test/*_test.rb']
end

RSpec::Core::RakeTask.new(:spec) 