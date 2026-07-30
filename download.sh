#!/usr/bin/env bash
# Pull Ohio HMDA Loan Application Register extracts from the CFPB Data Browser.
# The API 302-redirects to a pre-built file on files.ffiec.cfpb.gov, so -L is
# required; responses are gzipped, so --compressed is too.
set -euo pipefail
mkdir -p data
for year in 2022 2023 2024; do
  echo "downloading ${year}…"
  curl -sL --compressed -o "data/hmda_oh_${year}.csv" \
    "https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?states=OH&years=${year}"
  echo "  $(wc -l < "data/hmda_oh_${year}.csv") rows"
done
