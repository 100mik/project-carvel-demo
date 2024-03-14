#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

imgpkg push --file "$SCRIPT_DIR/repository" --bundle dgarnier963/demo/carvel-package-repo:reference
