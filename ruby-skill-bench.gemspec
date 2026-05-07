# frozen_string_literal: true

require_relative 'lib/skill_bench/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby-skill-bench'
  spec.version       = SkillBench::VERSION
  spec.authors       = ['Ismael Marin']
  spec.email         = ['ismael.marin@gmail.com']
  spec.summary       = 'The evaluation engine for AI Agent Skills benchmarking.'
  spec.homepage      = 'https://github.com/igmarin/ruby-skill-bench'
  spec.description   = <<~DESC
    ruby-skill-bench orchestrates evaluation runs of AI coding agents
    inside isolated git sandboxes, then scores the results using deterministic
    and LLM-powered judges.
  DESC
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.files         = Dir.chdir(__dir__) { Dir['lib/**/*.rb', 'bin/*', 'docs/**/*.md', 'README.md', 'LICENSE'] }
  spec.bindir        = 'bin'
  spec.executables   = ['skill-bench']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'activesupport', '>= 6.0'
  spec.add_dependency 'cgi',     '~> 0.5.1'
  spec.add_dependency 'dotenv',  '~> 3.2.0'
  spec.add_dependency 'faraday',  '~> 2.14'
  spec.add_dependency 'json',     '~> 2.19'
  spec.add_dependency 'parallel', '~> 1.26'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = 'https://github.com/igmarin/ruby-skill-bench'
end
