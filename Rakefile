require "bundler/setup"
require "rake/testtask"
require "rspec/core/rake_task"

task :default => [:unit_test]
task :all_test => [:unit_test, :int_test]
task :test => [:unit_test]

task :unit_test do
  execute_rspec("spec/unit/*_spec.rb")
end

task :int_test do
  execute_rspec("spec/int/*_spec.rb")
end

def execute_rspec(pattern) 
  RSpec::Core::RakeTask.new(:spec) do |tsk|
    tsk.pattern = pattern
  end
  Rake::Task["spec"].execute
end