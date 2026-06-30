# Examples

Runnable, copy-paste examples for `ruby-skill-bench`. Each one is offline by
default — they use the built-in `mock` provider, so they need **no API key and
no network access**.

## Index

### `offline-quickstart/`

A complete, self-contained eval (`evals/improve-greeting` + the
`skills/greeting-skill` skill) run end-to-end with the `mock` provider. Use this
to see the full flow — run, score, and the recorded trend file — without any
credentials.

Proof command:

```bash
cd examples/offline-quickstart
bundle exec skill-bench run evals/improve-greeting --skill skills/greeting-skill
```

This passes and exits `0`, and records the run to `.skill-bench-trends.json`
in that directory (gitignored — safe to delete). The convenience wrapper
`offline-quickstart/run.sh` runs the same command and prints the exit code and
the trend file.

### `api/`

The Ruby API example — drive `ruby-skill-bench` from code instead of the CLI.

Proof command:

```bash
bundle exec ruby examples/api/generate_scaffold.rb
```

> Note: this directory is added in a separate PR (#71); it is listed here so the
> index is complete.

### `ci/`

A copy-paste GitHub Actions workflow (`ci/github-action.yml`) that gates a skill
change on every pull request. It checks out the repo, sets up Ruby, installs the
gem, runs the offline-quickstart eval with `--format junit` writing `junit.xml`
(mock provider — no secrets), and uploads the report as an artifact.

The eval's process exit code is `0` on PASS and non-zero on FAIL, so the run
step gates the build. To preview the JUnit output locally:

```bash
cd examples/offline-quickstart
bundle exec skill-bench run evals/improve-greeting --skill skills/greeting-skill --format junit
```

See `ci/README.md` for how to adopt it in your own repo.
