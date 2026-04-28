#!/bin/bash
# Script: hello-world.sh
# Purpose: Print "Hola Mundo" 10 times (used in parallel pipeline job)

set -euo pipefail

ITERATION="${1:-unknown}"
echo "==================================================="
echo "Hola Mundo - Iteration #${ITERATION}"
echo "Executed at: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "Hostname: $(hostname)"
echo "==================================================="
