#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# Ruby API example: use ruby-skill-bench as a LIBRARY, not just the CLI.
#
# This script does two things, end to end and fully OFFLINE:
#
#   1. Scaffolds an eval (task + criteria + skill) with the public
#      `SkillBench::Services::TemplateRegistry` service.
#   2. Runs that eval programmatically with `SkillBench::Services::RunnerService`
#      and prints the verdict, using the built-in `mock` provider.
#
# "Offline" means no API keys and no network access are required: the
# `mock` provider returns deterministic judge scores, so the run is
# reproducible on any machine.
#
# Run it from the repo root:
#
#   bundle exec ruby examples/api/generate_scaffold.rb ; echo "exit=$?"
#
# A benign `Config load failed, using mock provider` line may appear on
# stderr — that is how the provider resolver reports "no LLM config, falling
# back to mock", which is exactly what we want here.
#
# Public API surface this example exercises:
#
#   SkillBench::Services::TemplateRegistry.call(type, category, vars)
#   SkillBench::Services::RunnerService.call(eval_name:, skill_names:)
#   SkillBench::OutputFormatter.format(result)   # human-readable report
#   SkillBench::OutputFormatter.exit_code(result) # 0 on PASS, 1 otherwise
# =============================================================================

require 'fileutils'
require 'json'
require 'skill_bench'

# Self-contained walkthrough of the scaffold-then-run library workflow.
module GenerateScaffoldExample
  module_function

  # The Rails pattern category to scaffold. TemplateRegistry ships several
  # (`:crud`, `:api`, `:controller`, `:model`, ...); see
  # `SkillBench::Services::TemplateRegistry::CATEGORIES`.
  CATEGORY = :crud

  # Names for the generated skill and eval. `{{skill_name}}` is interpolated
  # into the task.md and SKILL.md templates.
  SKILL_NAME = 'OrderCreator'
  SKILL_DIR  = 'order-creator'
  EVAL_DIR   = 'order-crud'

  # Generated artifacts live here. The directory is gitignored
  # (`examples/api/out/`) so nothing produced at runtime is ever committed.
  OUT_DIR = File.expand_path('out', __dir__)

  # Generate the scaffolding, run the eval offline, and exit with the verdict.
  def run
    reset_output_dir
    scaffold_eval
    scaffold_skill
    write_mock_config

    result = run_eval_offline
    report_result(result)
  end

  # Start each run from a clean output directory so repeated runs are
  # deterministic and never accumulate stale files.
  def reset_output_dir
    FileUtils.rm_rf(OUT_DIR)
    FileUtils.mkdir_p(eval_path)
    FileUtils.mkdir_p(skill_path)
  end

  # Render task.md and criteria.json from the template registry.
  #
  # `:task_md` interpolates `{{skill_name}}`; `:criteria_json` takes no
  # variables and now emits runtime-valid criteria — the five core scoring
  # dimensions with integer `max_score` values summing to 100, which is
  # exactly what the runtime criteria loader requires. (Earlier releases of
  # the generator emitted a drifted schema; that has since been fixed.)
  def scaffold_eval
    task_md = SkillBench::Services::TemplateRegistry.call(:task_md, CATEGORY, skill_name: SKILL_NAME)
    criteria_json = SkillBench::Services::TemplateRegistry.call(:criteria_json, CATEGORY)

    File.write(File.join(eval_path, 'task.md'), task_md)
    File.write(File.join(eval_path, 'criteria.json'), criteria_json)
  end

  # Render SKILL.md from the template registry. This is the skill context the
  # eval feeds to the "context" agent run (the baseline run sees no skill).
  def scaffold_skill
    skill_md = SkillBench::Services::TemplateRegistry.call(:skill_md, CATEGORY, skill_name: SKILL_NAME)
    File.write(File.join(skill_path, 'SKILL.md'), skill_md)
  end

  # Write a `skill-bench.json` that selects the offline `mock` provider.
  # RunnerService reads this file from the current working directory, so the
  # run below executes inside OUT_DIR (see `run_eval_offline`).
  def write_mock_config
    File.write(File.join(OUT_DIR, 'skill-bench.json'), JSON.generate(provider: 'mock'))
  end

  # Run the eval as a library call. RunnerService resolves the eval and skill
  # by path relative to the working directory, so we run from OUT_DIR. The
  # `Dir.chdir` block also keeps the recorded trend file (.skill-bench-trends.json)
  # inside the gitignored output directory.
  #
  # @return [Hash] the RunnerService result envelope.
  def run_eval_offline
    Dir.chdir(OUT_DIR) do
      SkillBench::Services::RunnerService.call(
        eval_name: "evals/#{EVAL_DIR}",
        skill_names: ["skills/#{SKILL_DIR}"]
      )
    end
  end

  # Print the human-readable report plus a one-line summary, then exit with the
  # verdict-derived code (0 on PASS, 1 otherwise).
  #
  # @param result [Hash] the RunnerService result envelope.
  def report_result(result)
    puts SkillBench::OutputFormatter.format(result)
    puts
    puts summary_line(result)

    exit SkillBench::OutputFormatter.exit_code(result)
  end

  # Build a compact "verdict + score" line from the delta report.
  #
  # @param result [Hash] the RunnerService result envelope.
  # @return [String] a single-line summary.
  def summary_line(result)
    report = result.dig(:response, :report)
    return "Run failed: #{result.dig(:response, :error, :message)}" unless report

    verdict = report.verdict ? 'PASS' : 'FAIL'
    "Summary: #{verdict} — context #{report.context_total}/100 vs baseline #{report.baseline_total}/100"
  end

  # @return [String] absolute path to the generated eval directory.
  def eval_path
    File.join(OUT_DIR, 'evals', EVAL_DIR)
  end

  # @return [String] absolute path to the generated skill directory.
  def skill_path
    File.join(OUT_DIR, 'skills', SKILL_DIR)
  end
end

GenerateScaffoldExample.run
