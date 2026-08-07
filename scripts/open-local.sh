#!/usr/bin/env bash
set -euo pipefail

script_path="$(readlink "${BASH_SOURCE[0]}" || true)"
if [[ -z "$script_path" ]]; then
  script_path="${BASH_SOURCE[0]}"
fi

repo_dir="$(cd "$(dirname "$script_path")/.." && pwd)"
cd "$repo_dir"

release_dir="$(swift build -c release --show-bin-path)"
open "$release_dir/CodeIsland.app"
