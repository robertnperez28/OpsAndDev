#!/bin/bash
# Script: create-files.sh
# Purpose: Create 10 files containing the current date, then print their contents

set -euo pipefail

OUTPUT_DIR="${1:-./generated-files}"
mkdir -p "${OUTPUT_DIR}"

echo "==> Generating 10 files in ${OUTPUT_DIR}"

for i in $(seq 1 10); do
  FILE="${OUTPUT_DIR}/file_${i}.txt"
  {
    echo "File number: ${i}"
    echo "Generated at: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo "Local date:   $(date)"
    echo "Random ID:    $(uuidgen 2>/dev/null || echo "id-${RANDOM}")"
  } > "${FILE}"
  echo "Created: ${FILE}"
done

echo ""
echo "==> Printing contents of all generated files:"
echo "==================================================="

for f in "${OUTPUT_DIR}"/file_*.txt; do
  echo "----- ${f} -----"
  cat "${f}"
  echo ""
done

echo "==> Done. Total files: $(ls -1 ${OUTPUT_DIR}/file_*.txt | wc -l)"
