#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
IMAGE="${PASCALC_DOCKER_IMAGE:-pascal-prolog-compiler:${VERSION}}"

if [[ $# -eq 0 ]]; then
  echo "Usage: ./scripts/pascalc-docker.sh <compiler-command> [args...]"
  echo "Example: ./scripts/pascalc-docker.sh build-asm examples/comprehensive_test.pas comprehensive_test"
  exit 1
fi

exec docker run --rm \
  -v "${REPO_ROOT}:/workspace" \
  -w /workspace \
  "${IMAGE}" \
  "$@"
