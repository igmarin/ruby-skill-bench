# Evaluator sandbox Docker image

Part of milestone **container-isolation-v1**. This document is the image contract
for `evaluator-sandbox`, the container SkillBench uses for isolated `run_command`
execution when a Docker daemon is available.

## Contract (MVP)

| Item | Value |
|------|--------|
| Image name | `evaluator-sandbox` (`Constants::Sandbox::DOCKER_IMAGE_NAME`) |
| Tags | `evaluator-sandbox:<SkillBench::VERSION>` and `evaluator-sandbox:latest` |
| Base | `ruby:3.4-bookworm` (aligns with CI Ruby 3.4; 3.3 hosts still run evals via host Ruby for the orchestrator) |
| Preinstalled | Ruby (from base), `git`, minimal Debian tools from base image |
| Working directory | `/sandbox` (host sandbox dir is bind-mounted here read-write) |
| Default process | `sleep infinity` — container stays up for `docker exec` |
| Network at runtime | **none** (`--network none`) — no `apt`/`bundle install` during evals |
| User | Host `uid:gid` via `docker run --user` |
| Privileges | `no-new-privileges`, `cap-drop ALL`, add back `CHOWN` + `DAC_OVERRIDE` only |

## Build

From the repo root (or any install that includes the packaged context):

```bash
bundle exec rake docker:build
```

This builds from `lib/skill_bench/execution/docker` and tags:

- `evaluator-sandbox:<version>` (from `SkillBench::VERSION`)
- `evaluator-sandbox:latest`

## Multi-arch notes

Build on the machine (or CI runner) that will run evals. Docker Desktop on Apple
Silicon produces arm64 images; GitHub `ubuntu-latest` produces amd64. Do not
assume a single cached image works across both without multi-platform build.

## Out of scope (MVP)

- Full Bundler/dev toolchain prebake
- Per-eval custom Dockerfiles
- Read-only root filesystem (documented as future hardening)
- gVisor / Firecracker
