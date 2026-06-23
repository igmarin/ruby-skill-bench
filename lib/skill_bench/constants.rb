# frozen_string_literal: true

module SkillBench
  # Centralized configuration constants for the SkillBench system.
  # This eliminates magic numbers and provides a single source of truth
  # for configurable values across the codebase.
  module Constants
    # ReAct Agent Configuration
    module ReactAgent
      DEFAULT_MAX_ITERATIONS = 25
      DEFAULT_MAX_DELAY = 30 # Maximum delay cap in seconds for retry logic
    end

    # HTTP Client Configuration
    module HttpClient
      DEFAULT_OPEN_TIMEOUT = 10
      DEFAULT_TIMEOUT = 120
      DEFAULT_MAX_RETRIES = 3
      DEFAULT_RETRY_DELAY = 1
      RETRYABLE_STATUSES = [429, 503].freeze
    end

    # Context Hydration Configuration
    module ContextHydration
      MAX_FILE_SIZE = 50_000 # Maximum file size in bytes
      MAX_TOTAL_CONTEXT_SIZE = 1_000_000 # Maximum total context size in bytes (1MB)
      TEXT_EXTENSIONS = %w[.md .rb .json .yml .yaml .txt].freeze
    end

    # Sandbox Configuration
    module Sandbox
      DOCKER_IMAGE_NAME = 'evaluator-sandbox'
    end

    # Tool Execution Configuration
    module Tools
      DANGEROUS_COMMANDS = %w[
        bash sh zsh fish dash ksh csh tcsh
        python python3 python2 ruby perl node
        php lua tcl wish
        curl wget nc ncat socat
        eval exec
        sudo su doas
        chmod chown mount umount
        dd mkfs fdisk parted
        insmod rmmod modprobe
        systemctl service
        passwd useradd userdel groupadd groupdel
      ].freeze
    end

    # File Path Configuration
    module FilePath
      ALLOWED_PATH_PATTERN = %r{\A[a-zA-Z0-9._\-/]+\z}
      MAX_PATH_LENGTH = 4096
    end
  end
end