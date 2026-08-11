#!/usr/bin/env ruby
# frozen_string_literal: true

# TemplateRegistry Demo
#
# This script demonstrates how to use SkillBench::Services::TemplateRegistry
# to generate eval scaffolding programmatically.
#
# Usage:
#   ruby examples/template_registry_demo.rb
#
# Or require it in your own scripts:
#   require_relative 'examples/template_registry_demo'

require_relative '../lib/skill_bench'

puts "SkillBench TemplateRegistry Demo"
puts "=" * 60
puts

# Demo 1: List all available categories
puts "1. Available Categories:"
puts "-" * 60
SkillBench::Services::TemplateRegistry::CATEGORIES.each do |category|
  puts "   - #{category}"
end
puts

# Demo 2: Generate task templates for different categories
puts "2. Task Templates (task_md):"
puts "-" * 60

%i[crud api background_job].each do |category|
  puts "\n--- #{category.upcase} ---"
  task = SkillBench::Services::TemplateRegistry.call(
    :task_md,
    category,
    skill_name: "MyService"
  )
  puts task
end

# Demo 3: Generate criteria JSON
puts "3. Criteria JSON (criteria_json):"
puts "-" * 60

%i[crud api].each do |category|
  puts "\n--- #{category.upcase} ---"
  criteria = SkillBench::Services::TemplateRegistry.call(:criteria_json, category)
  puts criteria
end

# Demo 4: Generate skill instructions
puts "4. Skill Instructions (skill_md):"
puts "-" * 60

%i[crud api background_job].each do |category|
  puts "\n--- #{category.upcase} ---"
  skill = SkillBench::Services::TemplateRegistry.call(
    :skill_md,
    category,
    skill_name: "MyService"
  )
  puts skill
end

# Demo 5: Variable interpolation
puts "5. Variable Interpolation:"
puts "-" * 60

task = SkillBench::Services::TemplateRegistry.call(
  :task_md,
  :api,
  skill_name: "PaymentGateway",
  endpoint: "/api/v1/payments"
)
puts task

# Demo 6: Complete workflow example
puts "6. Complete Workflow Example:"
puts "-" * 60
puts "Generating eval scaffolding for 'OrderService'..."
puts

skill_name = "OrderService"

# Generate all templates
task_md = SkillBench::Services::TemplateRegistry.call(:task_md, :crud, skill_name: skill_name)
criteria_json = SkillBench::Services::TemplateRegistry.call(:criteria_json, :crud)
skill_md = SkillBench::Services::TemplateRegistry.call(:skill_md, :crud, skill_name: skill_name)

# Show what would be written (dry run)
puts "Files that would be created:"
puts "  evals/order-service/task.md"
puts "  evals/order-service/criteria.json"
puts "  skills/order-service/SKILL.md"
puts
puts "To write these files, uncomment the following code:"
puts
puts "  FileUtils.mkdir_p('evals/order-service')"
puts "  File.write('evals/order-service/task.md', task_md)"
puts "  File.write('evals/order-service/criteria.json', criteria_json)"
puts
puts "  FileUtils.mkdir_p('skills/order-service')"
puts "  File.write('skills/order-service/SKILL.md', skill_md)"

puts
puts "=" * 60
puts "Demo complete!"
