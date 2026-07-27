#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/doctor.sh
source "$ROOT_DIR/lib/doctor.sh"
cd "$ROOT_DIR"
run_doctor
