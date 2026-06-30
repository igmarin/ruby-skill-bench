# Contributing to Ruby Skill Bench

Thank you for your interest in contributing to Ruby Skill Bench! This document provides guidelines and instructions for contributing to the project.

## Development Setup

### Prerequisites

- Ruby >= 3.1
- Bundler
- Git

### Setting Up the Development Environment

1. Clone the repository:
   ```bash
   git clone https://github.com/igmarin/ruby-skill-bench.git
   cd ruby-skill-bench
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Run the test suite:
   ```bash
   bundle exec rake test
   ```

4. Run RuboCop for code style checking:
   ```bash
   bundle exec rubocop
   ```

## Code Style and Conventions

### Ruby Style Guide

- Follow the [Ruby Style Guide](https://rubystyle.guide/)
- Use `# frozen_string_literal: true` at the top of every Ruby file
- Use meaningful variable and method names
- Keep methods under 20 lines when possible
- Use single quotes for strings unless interpolation is needed

### Service Object Pattern

- Use the `.call` class method pattern for service objects
- Return standardized response hashes: `{ success: true/false, response: { ... } }`
- Include YARD documentation for all public methods

### Error Handling

- Use the `ResponseBuilder` service object for standardized error responses
- Log errors using `SkillBench::ErrorLogger.log_error`
- Always include backtrace information in error logs

### Testing

- Write tests for all new features and bug fixes
- Use Minitest as the testing framework
- Follow the TDD (Test-Driven Development) approach when possible
- Test both success and failure paths
- Use descriptive test method names

### Documentation

- Add YARD documentation for all public methods
- Include `@param`, `@return`, and `@raise` tags
- Write clear and concise documentation
- Update the README when adding new features

## Contribution Workflow

### 1. Fork and Branch

1. Fork the repository on GitHub
2. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### 2. Make Changes

- Write clear, descriptive commit messages
- Follow the commit message format: `type: subject`
- Keep commits focused and atomic

### 3. Test Your Changes

- Run the full test suite: `bundle exec rake test`
- Run RuboCop: `bundle exec rubocop`
- Ensure all tests pass and code style is compliant

### 4. Submit a Pull Request

1. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Create a pull request on GitHub
3. Provide a clear description of your changes
4. Link to any relevant issues

## Code Review Process

All pull requests undergo code review. Be prepared to:

- Explain your design decisions
- Address reviewer feedback
- Make requested changes
- Update documentation as needed

## Release Process

Releases are managed by the maintainers. The process includes:

1. Updating the version number in `lib/skill_bench/version.rb`
2. Updating the CHANGELOG
3. Creating a git tag
4. Building and publishing the gem

## Reporting Issues

When reporting issues, please include:

- Ruby version
- SkillBench version
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Error messages and stack traces

## Security Considerations

To report a security vulnerability, please follow the process in
[SECURITY.md](SECURITY.md): do not open a public issue — use GitHub's private
vulnerability reporting or email the maintainer at
[ismael.marin@gmail.com](mailto:ismael.marin@gmail.com).

## License

By contributing to Ruby Skill Bench, you agree that your contributions will be licensed under the MIT License.