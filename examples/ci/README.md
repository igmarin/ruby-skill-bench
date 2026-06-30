# CI example

`github-action.yml` is a copy-paste GitHub Actions template that gates a skill
change on every PR by running the offline `mock`-provider eval with
`--format junit` (no secrets, no network). Copy it to
`.github/workflows/skill-bench.yml` in your own repo and adapt the paths.
