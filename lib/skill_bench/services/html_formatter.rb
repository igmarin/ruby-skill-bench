# frozen_string_literal: true

require 'cgi'
require_relative 'formatting_helpers'
require_relative '../delta_report'

module SkillBench
  module Services
    # Formats evaluation results as a complete, self-contained HTML document.
    #
    # The output embeds all styling inline (no external assets) and escapes every
    # dynamic, user-derived value with {CGI.escapeHTML} to prevent HTML injection.
    # Both the modern DeltaReport shape and the legacy result shape are supported.
    class HtmlFormatter
      extend FormattingHelpers

      # Inline stylesheet embedded in every generated document.
      STYLE = <<~CSS
        body { font-family: -apple-system, Segoe UI, Roboto, sans-serif; margin: 2rem; color: #1a1a1a; background: #fafafa; }
        main { max-width: 960px; margin: 0 auto; }
        header { border-bottom: 2px solid #ddd; padding-bottom: 1rem; margin-bottom: 1.5rem; }
        h1 { margin: 0 0 0.5rem; font-size: 1.6rem; }
        dl.meta { display: grid; grid-template-columns: max-content 1fr; gap: 0.2rem 1rem; margin: 0.5rem 0; }
        dl.meta dt { font-weight: 600; color: #555; }
        dl.meta dd { margin: 0; }
        p.usage { color: #555; font-variant-numeric: tabular-nums; }
        table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
        th, td { padding: 0.4rem 0.75rem; text-align: right; border-bottom: 1px solid #e2e2e2; }
        th:first-child, td:first-child { text-align: left; }
        tr.total td { font-weight: 700; border-top: 2px solid #bbb; }
        p.verdict { font-weight: 700; padding: 0.5rem 0.75rem; border-radius: 4px; display: inline-block; }
        p.verdict.pass { background: #e6f4ea; color: #1e7e34; }
        p.verdict.fail { background: #fde8e8; color: #c0392b; }
        p.error { color: #c0392b; }
        section.iterations h3 { margin-bottom: 0.25rem; }
        ol { margin: 0.25rem 0 1rem; }
        li { margin: 0.2rem 0; }
        span.tools, span.observation { color: #555; }
      CSS

      # Format an eval result as a full HTML document.
      #
      # @param result [Hash] Eval result envelope (DeltaReport or legacy shape).
      # @return [String] A complete HTML document string.
      def self.format(result)
        report = result.dig(:response, :report)
        body = report.is_a?(SkillBench::DeltaReport) ? delta_body(result, report) : legacy_section(result)
        build_document(result, body)
      end

      # Builds the body for a DeltaReport result (table plus iteration timeline).
      #
      # @param result [Hash] Eval result envelope.
      # @param report [SkillBench::DeltaReport] The delta report.
      # @return [String] HTML for the report and iteration sections.
      def self.delta_body(result, report)
        "#{report_section(report)}\n#{iterations_section(result)}"
      end
      private_class_method :delta_body

      # Wraps body HTML in a complete, styled HTML document.
      #
      # @param result [Hash] Eval result envelope (used for the header/title).
      # @param body [String] Pre-rendered body HTML.
      # @return [String] A complete HTML document string.
      def self.build_document(result, body)
        title = escape(result[:eval_name] || 'Report')
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
          <meta charset="utf-8">
          <title>SkillBench Report — #{title}</title>
          <style>#{STYLE}</style>
          </head>
          <body>
          <main>
          #{header_html(result)}
          #{body}
          </main>
          </body>
          </html>
        HTML
      end
      private_class_method :build_document

      # Builds the header with eval/skill/provider names and the usage line.
      #
      # @param result [Hash] Eval result envelope.
      # @return [String] HTML for the document header.
      def self.header_html(result)
        <<~HTML.chomp
          <header>
          <h1>SkillBench Report</h1>
          <dl class="meta">
          <dt>Eval</dt><dd>#{escape(result[:eval_name])}</dd>
          <dt>Skill</dt><dd>#{escape(result[:skill_name])}</dd>
          <dt>Provider</dt><dd>#{escape(result[:provider_name])}</dd>
          </dl>
          <p class="usage">#{usage_line(result)}</p>
          </header>
        HTML
      end
      private_class_method :header_html

      # Builds the token/cost summary line for the header.
      #
      # @param result [Hash] Eval result envelope; reads :tokens and :cost.
      # @return [String] An escaped "Tokens / Est. Cost" line.
      def self.usage_line(result)
        tokens = result[:tokens] || {}
        total = tokens[:total_tokens] || tokens['total_tokens'] || 0
        cost = result[:cost]
        cost_label = cost ? Kernel.format('$%.4f', cost) : '—'
        "Tokens: #{escape(total)} | Est. Cost: #{escape(cost_label)}"
      end
      private_class_method :usage_line

      # Builds the scoring table and verdict for a DeltaReport.
      #
      # @param report [SkillBench::DeltaReport] The delta report.
      # @return [String] HTML for the report section.
      def self.report_section(report)
        <<~HTML.chomp
          <section class="report">
          <h2>Delta Report</h2>
          <table>
          <thead><tr><th>Dimension</th><th>Baseline</th><th>Context</th><th>Delta</th></tr></thead>
          <tbody>
          #{dimension_rows(report)}
          #{total_row(report)}
          </tbody>
          </table>
          #{verdict_html(report)}
          </section>
        HTML
      end
      private_class_method :report_section

      # Builds one table row per scored dimension.
      #
      # @param report [SkillBench::DeltaReport] The delta report.
      # @return [String] HTML table rows joined by newlines.
      def self.dimension_rows(report)
        report.deltas.map { |name, delta| dimension_row(name, delta, report) }.join("\n")
      end
      private_class_method :dimension_rows

      # Builds a single dimension table row.
      #
      # @param name [String] Dimension name.
      # @param delta [Numeric] Context-minus-baseline delta.
      # @param report [SkillBench::DeltaReport] The delta report.
      # @return [String] An HTML table row.
      def self.dimension_row(name, delta, report)
        dim = report.criteria.dimensions.find { |candidate| candidate.name == name }
        humanized = humanize(name)
        label = dim ? "#{humanized} (#{dim.max_score})" : humanized
        baseline = report.baseline_scores[name]
        context = report.context_scores[name]
        row_cells('dimension', label, baseline, context, delta_str(delta))
      end
      private_class_method :dimension_row

      # Builds the totals table row.
      #
      # @param report [SkillBench::DeltaReport] The delta report.
      # @return [String] An HTML table row for the totals.
      def self.total_row(report)
        total_delta = report.deltas.values.sum
        row_cells('total', 'Total', "#{report.baseline_total}/100",
                  "#{report.context_total}/100", delta_str(total_delta))
      end
      private_class_method :total_row

      # Builds an HTML table row from escaped cell values.
      #
      # @param css_class [String] CSS class for the row.
      # @param label [String] First-column label.
      # @param baseline [Object] Baseline score cell.
      # @param context [Object] Context score cell.
      # @param delta [String] Delta cell.
      # @return [String] An HTML table row.
      def self.row_cells(css_class, label, baseline, context, delta)
        "<tr class=\"#{css_class}\"><td>#{escape(label)}</td><td>#{escape(baseline)}</td>" \
          "<td>#{escape(context)}</td><td>#{escape(delta)}</td></tr>"
      end
      private_class_method :row_cells

      # Builds the verdict paragraph.
      #
      # @param report [SkillBench::DeltaReport] The delta report.
      # @return [String] An HTML verdict paragraph.
      def self.verdict_html(report)
        verdict = report.verdict
        criteria = report.criteria
        status = verdict ? 'PASS' : 'FAIL'
        css = verdict ? 'pass' : 'fail'
        threshold = escape(criteria.pass_threshold)
        minimum_delta = escape(criteria.minimum_delta)
        %(<p class="verdict #{css}">Verdict: #{status} (threshold: #{threshold}, minimum delta: #{minimum_delta})</p>)
      end
      private_class_method :verdict_html

      # Builds the baseline/context iteration timeline section.
      #
      # @param result [Hash] Eval result envelope.
      # @return [String] HTML for the iterations section, or empty string.
      def self.iterations_section(result)
        baseline = result.dig(:response, :baseline_iterations) || []
        context = result.dig(:response, :context_iterations) || []
        baseline_empty = baseline.empty?
        context_empty = context.empty?
        return '' if baseline_empty && context_empty

        blocks = []
        blocks << iteration_block('Baseline Iterations', baseline) unless baseline_empty
        blocks << iteration_block('Context Iterations', context) unless context_empty
        %(<section class="iterations">\n<h2>Iteration Timeline</h2>\n#{blocks.join("\n")}\n</section>)
      end
      private_class_method :iterations_section

      # Builds one named iteration timeline block.
      #
      # @param title [String] Section title.
      # @param iterations [Array<Hash>] Iteration metadata entries.
      # @return [String] HTML for the timeline block.
      def self.iteration_block(title, iterations)
        items = iterations.map { |iteration| iteration_item(iteration) }.join("\n")
        %(<div class="timeline"><h3>#{escape(title)}</h3><ol>\n#{items}\n</ol></div>)
      end
      private_class_method :iteration_block

      # Builds one list item for a single iteration step.
      #
      # @param iteration [Hash] Iteration metadata with :step_number, :thought,
      #   :tools_used, and :observation_summary keys.
      # @return [String] An HTML list item.
      def self.iteration_item(iteration)
        tools = iteration[:tools_used] || []
        tools_html = tools.empty? ? '' : %( <span class="tools">Tools: #{escape(tools.join(', '))}</span>)
        observation = iteration[:observation_summary].to_s
        observation_html = observation.empty? ? '' : %( <span class="observation">Observation: #{escape(observation)}</span>)
        step = "Step #{escape(iteration[:step_number])}: #{escape(iteration[:thought])}"
        %(<li><span class="thought">#{step}</span>#{tools_html}#{observation_html}</li>)
      end
      private_class_method :iteration_item

      # Builds the body for a legacy (non-DeltaReport) result.
      #
      # @param result [Hash] Legacy eval result envelope.
      # @return [String] HTML for the legacy status section.
      def self.legacy_section(result)
        passed = result[:pass]
        status = passed ? 'PASSED' : 'FAILED'
        css = passed ? 'pass' : 'fail'
        score = result[:score]&.round(2)
        <<~HTML.chomp
          <section class="report legacy">
          <h2>Result</h2>
          <p class="verdict #{css}">Status: #{status}</p>
          <p class="score">Score: #{escape(score || 'N/A')}</p>
          #{legacy_error(result)}
          </section>
        HTML
      end
      private_class_method :legacy_section

      # Builds the optional error paragraph for a legacy result.
      #
      # @param result [Hash] Legacy eval result envelope.
      # @return [String] An HTML error paragraph, or empty string.
      def self.legacy_error(result)
        message = result.dig(:response, :error, :message)
        message ? %(<p class="error">Error: #{escape(message)}</p>) : ''
      end
      private_class_method :legacy_error

      # Escapes any value for safe HTML embedding.
      #
      # @param value [Object] The value to escape (coerced via #to_s).
      # @return [String] HTML-escaped text.
      def self.escape(value)
        CGI.escapeHTML(value.to_s)
      end
      private_class_method :escape
    end
  end
end
