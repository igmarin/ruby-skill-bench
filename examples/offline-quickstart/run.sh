#!/usr/bin/env bash
set -euo pipefail

# Run a full skill-bench eval fully offline using the built-in `mock` provider.
# No API keys and no network access are required.

# Always run from this script's own directory so the eval/skill resolve by path.
cd "$(dirname "$0")"

echo "==> Running offline eval with the mock provider (no API key, no network)"
set +e
bundle exec skill-bench run evals/improve-greeting --skill skills/greeting-skill
exit_code=$?
set -e

echo "exit=${exit_code}"

echo "==> Recorded run (.skill-bench-trends.json):"
if [ -f .skill-bench-trends.json ]; then
  cat .skill-bench-trends.json
else
  echo "(no .skill-bench-trends.json produced)"
fi

exit "${exit_code}"
