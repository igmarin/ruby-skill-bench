# frozen_string_literal: true

require 'rake/testtask'
require 'reek/rake/task'
require 'rubocop/rake_task'
require 'yard'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

RuboCop::RakeTask.new(:rubocop)

Reek::Rake::Task.new(:reek) do |t|
  t.config_file = '.reek.yml'
  t.source_files = 'lib'
end

YARD::Rake::YardocTask.new(:yard)

namespace :yard do
  desc 'Fail the build when any public or protected method lacks YARD documentation'
  task :coverage do
    YARD::Registry.clear
    YARD.parse(Dir['lib/**/*.rb'])

    undocumented = YARD::Registry.all(:method).select do |method|
      next false if method.visibility == :private

      # YARD auto-adds "@return a new instance of X" to bare initializers; that is not real documentation.
      meaningful_tags = method.tags.reject { |tag| tag.tag_name == 'return' && tag.text.to_s.start_with?('a new instance of') }
      method.docstring.to_s.strip.empty? && meaningful_tags.empty?
    end

    if undocumented.empty?
      puts 'YARD doc coverage: 0 undocumented public objects.'
    else
      warn "YARD doc coverage failed: #{undocumented.size} undocumented public object(s):"
      undocumented.sort_by(&:path).each { |method| warn "  #{method.path} (#{method.file}:#{method.line})" }
      abort
    end
  end
end

namespace :package do
  desc 'Build the evaluator gem'
  task :build do
    sh 'gem build ruby-skill-bench.gemspec'
  end

  desc 'Verify the evaluator gem contains required release files'
  task verify: :build do
    gem_path = FileList['ruby-skill-bench-*.gem'].max_by { |path| File.mtime(path) }
    abort('No built evaluator gem found') unless gem_path

    require_relative 'lib/skill_bench'
    result = SkillBench::PackageVerifier.call(package_path: gem_path)
    abort(result[:response][:error][:message]) unless result[:success]
  end
end

task default: %i[rubocop reek test]
