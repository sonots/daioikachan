#!/usr/bin/env rake

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = (Dir["test/plugin/test_*.rb"] - ["helper.rb"]).sort
  test.verbose = true
end

task :default => [:test]
