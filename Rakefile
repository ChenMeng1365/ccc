require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.rspec_opts = "--format documentation --color"
end

desc "Run all tests (default)"
task test: :spec

desc "Run the built-in demo for both encoders"
task :demo do
  ruby "examples/ruby/stego_encoder_demo.rb"
  ruby "examples/ruby/unicode_stego_demo.rb"
end

desc "Run RuboCop lint"
task :lint do
  sh "bundle exec rubocop lib/"
end

task default: :test
