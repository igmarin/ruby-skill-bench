# SkillBench evaluator-sandbox image contract (MVP)
#
# Purpose: long-lived container for `docker exec` of allowlisted agent commands.
# Runtime flags (from Sandbox#start_container): --network none, non-root uid/gid,
#   --security-opt no-new-privileges, --cap-drop ALL (+ CHOUN/DAC_OVERRIDE).
#
# Assumptions:
# - No package installs or gem fetches during an eval (network is disabled at runtime).
# - Ruby major tracks CI (3.3/3.4). Bookworm image provides a modern baseline.
# - git is available for tools that shell out to git inside the sandbox mount.
# - Multi-arch: build on the host arch (arm64 Mac / amd64 CI) via docker build.
#
# See docs/docker.md and milestone container-isolation-v1.

FROM ruby:3.4-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /sandbox

# Keep the container alive so repeated `docker exec` sessions can run commands.
CMD ["sleep", "infinity"]
