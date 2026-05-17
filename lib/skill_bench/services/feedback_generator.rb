# frozen_string_literal: true

require_relative 'formatting_helpers'

module SkillBench
  module Services
    # Categorizes dimension scores into "what went well", "what went wrong",
    # and actionable advice based on judge reasoning.
    class FeedbackGenerator
      extend FormattingHelpers

      # Generates feedback sections from a DeltaReport.
      #
      # @param report [SkillBench::DeltaReport] The delta report.
      # @return [Hash] Standardized response hash:
      #   - { success: true, response: { output: String } }
      def self.call(report)
        output = generate_feedback(report)
        { success: true, response: { output: output } }
      end

      private_class_method def self.generate_feedback(report)
        return '' unless feedback_applicable?(report)

        context_dims = report.context_dimensions || {}
        baseline_dims = report.baseline_dimensions || {}
        well, wrong, advice = categorize_dimensions(context_dims, baseline_dims, report)

        assemble_feedback_lines(well, wrong, advice)
      end

      private_class_method def self.feedback_applicable?(report)
        return false unless report.respond_to?(:baseline_dimensions) && report.respond_to?(:context_dimensions)

        context_dims = report.context_dimensions || {}
        baseline_dims = report.baseline_dimensions || {}
        context_dims.any? { |name, dim| baseline_dims[name] && dim }
      end

      private_class_method def self.categorize_dimensions(context_dims, baseline_dims, report)
        well = []
        wrong = []
        advice = []

        context_dims.each do |name, dim|
          baseline_dim = baseline_dims[name]
          next unless baseline_dim && dim

          cat = categorize_dimension(name, dim, baseline_dim, report)
          well.concat(cat[:well])
          wrong.concat(cat[:wrong])
          advice.concat(cat[:advice])
        end

        [well, wrong, advice]
      end

      private_class_method def self.categorize_dimension(name, dim, baseline_dim, report)
        values = extract_values(dim, baseline_dim)
        score = values[:score]
        max_score = values[:max_score]
        baseline_score = values[:baseline_score]
        reasoning = values[:reasoning]

        pct = compute_percentage(score, max_score)
        dim_obj = report.criteria.dimensions.find { |d| d.name == name }
        humanized = humanize(name)
        label = "#{humanized} (#{score}/#{max_score}, baseline: #{baseline_score}/#{max_score})"

        build_categorization(pct, label, reasoning, humanized, dim_obj)
      end

      private_class_method def self.extract_values(dim, baseline_dim)
        {
          score: dim[:score] || dim['score'] || 0,
          max_score: dim[:max_score] || dim['max_score'] || 1,
          reasoning: dim[:reasoning] || dim['reasoning'] || '',
          baseline_score: baseline_dim[:score] || baseline_dim['score'] || 0
        }
      end

      private_class_method def self.compute_percentage(score, max_score)
        max_score.positive? ? (score.to_f / max_score * 100).round : 0
      end

      private_class_method def self.build_categorization(pct, label, reasoning, humanized, dim_obj)
        well = []
        wrong = []
        advice = []
        has_reasoning = !reasoning.empty?

        if pct >= 80
          well << "  #{label}"
          well << "    #{reasoning}" if has_reasoning
        else
          wrong << "  #{label}"
          wrong << "    #{reasoning}" if has_reasoning
          dim_advice = dim_obj&.description.to_s
          advice << "  #{humanized}: #{dim_advice}" unless dim_advice.empty?
        end

        { well: well, wrong: wrong, advice: advice }
      end

      private_class_method def self.assemble_feedback_lines(well, wrong, advice)
        lines = []
        append_section(lines, 'WHAT WENT WELL', well)
        append_section(lines, 'WHAT WENT WRONG', wrong)
        append_section(lines, 'ADVICE', advice)
        lines.join("\n")
      end

      private_class_method def self.append_section(lines, title, items)
        return if items.empty?

        lines << ''
        lines << "  === #{title} ==="
        lines.concat(items)
      end
    end
  end
end
