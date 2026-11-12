#!/usr/bin/env bash
# Run: bash ralph.sh [paper|slides|both] [iterations, default 5]
# Inputs: BRIEF.md, PROMPT.md, supplied research files, and previous output/.
# Outputs: output/*.tex, output/*.pdf, PROGRESS.md, and logs/ per run.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
target=${1:-both}
limit=${2:-5}
case "$target" in
  paper) documents=(paper) ;;
  slides) documents=(slides) ;;
  both) documents=(paper slides) ;;
  *) echo 'Usage: bash ralph.sh [paper|slides|both] [positive iterations]' >&2; exit 2 ;;
esac
[[ $limit =~ ^[1-9][0-9]*$ ]] || { echo 'Iterations must be positive.' >&2; exit 2; }
for tool in codex pdflatex biber; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool. Ask the user to install it." >&2; exit 1; }
done
[[ -s BRIEF.md && -s PROMPT.md ]] || { echo 'BRIEF.md and PROMPT.md are required.' >&2; exit 1; }
mkdir -p output logs
run=$(mktemp -d logs/run-XXXXXXXX)

build() (
  cd output
  for doc in "${documents[@]}"; do
    pdflatex -interaction=nonstopmode -halt-on-error -no-shell-escape "$doc.tex" || exit 1
    if [[ -f $doc.bcf ]]; then biber "$doc" || exit 1; fi
    pdflatex -interaction=nonstopmode -halt-on-error -no-shell-escape "$doc.tex" || exit 1
    pdflatex -interaction=nonstopmode -halt-on-error -no-shell-escape "$doc.tex" || exit 1
    [[ -s $doc.pdf ]] || exit 1
  done
)

for ((i=1; i<=limit; i++)); do
  echo "Iteration $i/$limit ($target); logs: $run"
  {
    cat PROMPT.md
    printf '\nRequested output: %s. Iteration: %s/%s.\n' "$target" "$i" "$limit"
    printf 'Read BRIEF.md and PROGRESS.md if present. Previous build log: %s/build.log (if present).\n' "$run"
  } | codex exec --sandbox workspace-write --skip-git-repo-check \
      --output-last-message "$run/reply.txt" - >"$run/iteration-$i.log" 2>&1
  if build >"$run/build.log" 2>&1; then
    if [[ $(cat "$run/reply.txt") == 'DONE' ]]; then
      echo 'Complete. See output/ and PROGRESS.md.'
      exit 0
    fi
  fi
done
echo "Iteration limit reached. Review PROGRESS.md and $run/build.log." >&2
exit 1
