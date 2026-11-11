#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ../.work/demo-checks
swiftc -module-cache-path ../.work/demo-checks/cache CaresoftVoiceDemo/DemoConfiguration.swift Tests/ConfigurationChecks.swift -o ../.work/demo-checks/check
../.work/demo-checks/check
