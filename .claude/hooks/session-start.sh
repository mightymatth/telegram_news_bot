#!/bin/bash
set -euo pipefail

# Only run in remote (Claude Code on the web) environment
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Install a compatible Bundler 2.x version (the lockfile requires Bundler 2.x,
# and the pre-installed Bundler 4.x has CGI compatibility issues with Ruby 3.3)
gem install bundler -v '~> 2.5' --no-document

# Install Ruby dependencies via Bundler
BUNDLE_SILENCE_ROOT_WARNING=1 bundle _2.7.2_ install
