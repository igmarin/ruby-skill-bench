# Minimal evaluator sandbox for SkillBench agent command isolation.
# Runtime isolation uses --network none; do not rely on package installs during evals.
# Image contract is refined in milestone container-isolation-v1 (#87).
FROM ruby:3.4-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /sandbox

# Keep the container alive so `docker exec` can run allowlisted commands.
CMD ["sleep", "infinity"]
