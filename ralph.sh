#!/usr/bin/env bash
# Run: bash ralph.sh [paper|slides|both] [iterations] [--agent claude|codex] [--format quarto|latex] [--language R|python|both] [--silent]
# Inputs: BRIEF.md, PROMPT.md, supplied research files, and previous output/.
# Outputs: output/*.qmd or *.tex, PDFs, analysis code, PROGRESS.md, and logs/ per run.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
usage() {
  echo 'Usage: bash ralph.sh [paper|slides|both] [positive iterations] [--agent claude|codex] [--format quarto|latex] [--language R|python|both] [--silent]'
  echo 'Defaults: both documents, 5 iterations, Claude Code, Quarto format, R and Python code, agent output shown (--silent: status lines only).'
}
agent=claude
format=quarto
language=both
silent=0
positional=()
while (($#)); do
  case "$1" in
    --agent|--format|--language)
      option=$1
      [[ $# -ge 2 && $2 != --* ]] || { echo "Missing value for $option." >&2; usage >&2; exit 2; }
      case "$option" in
        --agent) agent=$2 ;;
        --format) format=$2 ;;
        --language) language=$2 ;;
      esac
      shift 2 ;;
    --silent) silent=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) positional+=("$1"); shift ;;
  esac
done
[[ ${#positional[@]} -le 2 ]] || { usage >&2; exit 2; }
target=${positional[0]:-both}
limit=${positional[1]:-5}
case "$format" in
  quarto|latex) ;;
  *) echo 'Format must be quarto or latex.' >&2; exit 2 ;;
esac
case "$language" in
  R|r) language=R ;;
  python|both) ;;
  *) echo 'Language must be R, python, or both.' >&2; exit 2 ;;
esac
case "$target" in
  paper) documents=(paper) ;;
  slides) documents=(slides) ;;
  both) documents=(paper slides) ;;
  *) usage >&2; exit 2 ;;
esac
[[ $limit =~ ^[1-9][0-9]*$ ]] || { echo 'Iterations must be positive.' >&2; exit 2; }
case "$agent" in
  codex|claude) ;;
  *) echo 'Agent must be claude or codex.' >&2; exit 2 ;;
esac
required_tools=("$agent")
[[ $agent != claude ]] || required_tools+=(jq)
if [[ $format == quarto ]]; then
  required_tools+=(quarto)
else
  required_tools+=(pdflatex biber)
fi
for tool in "${required_tools[@]}"; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool. Ask the user to install it." >&2; exit 1; }
done
[[ -s BRIEF.md && -s PROMPT.md ]] || { echo 'BRIEF.md and PROMPT.md are required.' >&2; exit 1; }
mkdir -p output logs
run=logs/run-$(date +%Y-%m-%d_%H-%M-%S)
mkdir "$run"  # fails rather than mixing logs if two runs start in the same second

build() (
  cd output
  for doc in "${documents[@]}"; do
    if [[ $format == quarto ]]; then
      quarto_format=pdf
      [[ $doc != slides ]] || quarto_format=beamer
      quarto render "$doc.qmd" --to "$quarto_format" || exit 1
      [[ -s $doc.pdf ]] || exit 1
      continue
    fi
    pdflatex -interaction=nonstopmode -halt-on-error -no-shell-escape "$doc.tex" || exit 1
    if [[ -f $doc.bcf ]]; then biber "$doc" || exit 1; fi
    pdflatex -interaction=nonstopmode -halt-on-error -no-shell-escape "$doc.tex" || exit 1
    pdflatex -interaction=nonstopmode -halt-on-error -no-shell-escape "$doc.tex" || exit 1
    [[ -s $doc.pdf ]] || exit 1
  done
)

# Claude streams JSON events; jq shows its messages and one line per tool call.
claude_view='fromjson? |
  if .type == "assistant" then .message.content[] |
    if .type == "text" then .text + "\n"
    elif .type == "tool_use" then "  > \(.name) \(.input.command // .input.file_path // .input.pattern // .input.query // .input.url // "" | split("\n")[0][0:100])\n"
    else empty end
  elif .type == "result" then "  Agent finished: \(.num_turns) turns, \(.duration_ms / 60000 | floor) min, $\(.total_cost_usd)\n"
  else empty end'

# Print agent output unless --silent; the full output is always in the log.
show() { if [[ $silent == 1 ]]; then cat >/dev/null; else "$@"; fi; }

run_agent() {
  local log="$run/iteration-$i.log"
  case "$agent" in
    codex)
      codex exec --sandbox workspace-write --skip-git-repo-check \
        --output-last-message "$run/reply.txt" - 2>&1 | tee "$log" | show cat ;;
    claude)
      claude -p --output-format stream-json --verbose --permission-mode acceptEdits \
        --allowedTools 'Read,Edit,Write,Glob,Grep,Bash,WebSearch,WebFetch' |
        tee "$log" | show jq -Rrj --unbuffered "$claude_view"
      # Keep only the final response for the exact DONE check.
      jq -Rr 'fromjson? | select(.type == "result") | .result' "$log" >"$run/reply.txt" ;;
  esac
}

for ((i=1; i<=limit; i++)); do
  echo "Iteration $i/$limit ($agent, $target, $format, $language); logs: $run"
  {
    cat PROMPT.md
    printf '\nRequested output: %s. Iteration: %s/%s.\n' "$target" "$i" "$limit"
    printf 'Document format: %s. Code language: %s.\n' "$format" "$language"
    printf 'Read BRIEF.md and PROGRESS.md if present. Previous build log: %s/build.log (if present).\n' "$run"
  } | run_agent
  if build >"$run/build.log" 2>&1; then
    echo "  Build succeeded."
    if [[ $(cat "$run/reply.txt") == 'DONE' ]]; then
      echo 'Complete. See output/ and PROGRESS.md.'
      exit 0
    fi
    echo "  Agent did not reply DONE; continuing."
  else
    echo "  Build failed; see $run/build.log. Errors go to the next iteration."
  fi
done
echo "Iteration limit reached. Review PROGRESS.md and $run/build.log." >&2
exit 1
