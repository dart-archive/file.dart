#!/bin/bash

# Fast fail the script on failures.
set -e

# Skipping this until at least we have a dev release that aligns with dart_style version
# $(dirname -- "$0")/ensure_dartfmt.sh

# Run the tests.
pub run test

dartanalyzer --strong lib/file.dart
dartanalyzer --strong lib/io.dart
dartanalyzer --strong lib/sync.dart
dartanalyzer --strong lib/sync_io.dart

# Install dart_coveralls; gather and send coverage data.
if [ "$COVERALLS_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "stable" ]; then
  pub global activate dart_coveralls
  pub global run dart_coveralls report \
    --retry 2 \
    --exclude-test-files \
    tool/test_all_for_coverage.dart
fi
