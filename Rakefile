# encoding: utf-8

require 'rubygems'
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "fancy-open-struct #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :fix_permissions do
  File.umask 0022
  filelist = `git ls-files`.split("\n")
  FileUtils.chmod 0644, filelist, :verbose => true
  FileUtils.chmod 0755, ['lib', 'spec'], :verbose => true
end

task :build => :fix_permissions

task :default => :spec