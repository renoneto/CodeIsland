#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

release_dir="$(swift build -c release --show-bin-path)"
open "$release_dir/CodeIsland.app"
