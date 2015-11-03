require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "spec"
  t.test_files = FileList['spec/*_spec.rb']
  t.verbose = true
end

task :spec => :test
task :default => :test
