#!/usr/bin/env bash

# Turns a plain word list into a Hunspell dictionary.

set -euo pipefail

INPUT="${1:?terms input file required}"
BASE_OUT="${2:-generated}"

# Static .aff — write once, never touch again
cat > "${BASE_OUT}.aff" <<'EOF'
SET UTF-8
TRY esianrtolcdugmphbyfvkwzESIANRTOLCDUGMPHBYFVKWZ'
WORDCHARS 0123456789.-
KEEPCASE K
SFX S Y 3
SFX S   0   s    [^sxzhy]
SFX S   0   es   [sxz]
SFX S   y   ies  [^aeiou]y
SFX B Y 2
SFX B   0   ed   [^ey]
SFX B   e   ed   e
SFX C Y 2
SFX C   0   ing  [^e]
SFX C   e   ing  e
EOF

# ── Generate .dic with auto-flagging ──────────────────────────────────
count=$(grep -cv '^\s*$\|^#' "$INPUT")
{
  echo "$count"
  # Flag auto-assignment by word shape:
  #   - contains digits or dots (EC2, m5.metal) → /K  (keepcase only)
  #   - ALL CAPS (EKS, OIDC)                    → /KS (keepcase + plural)
  #   - Starts uppercase (DaemonSet, Pod)        → /KS (keepcase + plural)
  #   - Starts lowercase (deploy, drain)         → /BCS (verb: -ed, -ing, -s)
  # `|| [[ -n "$word" ]]` ensures the last line is read even without a trailing newline
  while IFS= read -r word || [[ -n "$word" ]]; do
    [[ -z "$word" || "$word" == \#* ]] && continue
    if [[ "$word" =~ [0-9] || "$word" =~ \. ]]; then
      echo "${word}/K"       # technical identifier — preserve exact casing, no inflections
    elif [[ "$word" =~ ^[A-Z][A-Z0-9_-]+$ ]]; then
      echo "${word}/KS"      # acronym — preserve casing, allow plural (-s)
    elif [[ "$word" =~ ^[A-Z] ]]; then
      echo "${word}/KS"      # proper noun / CamelCase — preserve casing, allow plural
    elif [[ "$word" =~ ^[a-z] ]]; then
      echo "${word}/BCS"     # verb/common term — allow -ed, -ing, -s conjugations
    else
      echo "${word}"
    fi
  done < "$INPUT"
} > "${BASE_OUT}.dic"
