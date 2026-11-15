# Agentic coding: Between performance boost and verification debt

Materials accompanying our workshop at the **TRR 266 Annual Conference 2026**,
Leibniz Universität Hannover. The repository contains the presentation slides
and a [Ralph Wiggum](https://ghuntley.com/ralph/) example showing a simple agent
setup.

The example wraps Claude Code (default) or Codex in a short Bash loop: give the
agent a brief, let it work on files, compile its output, and feed build errors
back into the next iteration. Its memory is formed by files that you can inspect
and edit.


## What's here

- [`docs/trr266_ac26_agents_wshop.qmd`](docs/trr266_ac26_agents_wshop.qmd):
  workshop slides.
- [`ralph.sh`](ralph.sh): the minimal Ralph Wiggum loop.
- [`BRIEF.md`](BRIEF.md): the research task to give the agent.
- [`PROMPT.md`](PROMPT.md): instructions reused on each iteration.
- [`materials/`](materials/): the Beamer theme and logo for the example.
- [`.devcontainer/`](.devcontainer/): the development environment.

Ralph writes generated documents, analysis code, and results to `output/`,
iteration and build logs to `logs/`, and progress notes to `PROGRESS.md`.
The output and log directories are ignored by Git.


## Get started

Open the repository in its devcontainer and let setup finish. It provides
R and tidyverse, Python, Quarto, TinyTeX, DBI/RPostgres, and PostgreSQL client
tools, as well as the Codex and Claude Code CLIs and VS Code extensions;
authenticate your chosen CLI before running the example.

To render just the workshop presentation (the PDF is already included in
`docs/`):

```bash
quarto render docs/trr266_ac26_agents_wshop.qmd
```


## Try the Ralph Wiggum example

Read and adapt `BRIEF.md` before running. The included example asks for an MBA
slide deck about U.S. firms' price-to-earnings ratios using WRDS Compustat data;
running it requires your own authorized data access and database configuration.
You can replace the brief with a task suited to your own inputs.

Run `python3 scripts/configure_wrds.py` in your terminal to enter your WRDS
username and password (password input is hidden). This adds or updates the
`[wrds]` service in `~/.pg_service.conf` and sets file permissions to `600`.
This means that credentials stay outside the repository, but processes running
as your OS user can still read the file.

Then you can start the loop, for example by calling one of the following 
commands:

```bash
bash ralph.sh slides 5
bash ralph.sh slides 5 --agent codex
bash ralph.sh paper 5 --format latex --language python
```

Arguments:

- `--agent claude|codex` (default: `claude`). Run `claude` (or `codex`) once
  to sign in before using the respective CLI.
- Target: `paper`, `slides`, or `both` (default: `both`).
- Maximum number of iterations: a positive integer (default: `5`).
- `--format quarto|latex` (default: `quarto`).
- `--language R|python|both` (default: `both`; `r` is also accepted).
- `--silent`: print only status lines instead of the progress view; full
  output still goes to the logs.

Each iteration starts a fresh invocation of the selected agent, which reads the
brief and existing work, updates files and progress notes, and attempts to
compile the requested documents. The loop stops when the agent replies exactly
`DONE` and compilation succeeds, or when it reaches the iteration limit. Each
invocation consumes your selected provider's normal usage; the iteration count
does not limit its duration.

Claude Code runs in noninteractive print mode with file edits, shell commands,
and web tools pre-approved for the research workflow. Codex, selected with
`--agent codex`, runs via `codex exec` in its workspace-write sandbox and uses
the same prompt, progress file, build checks, and `DONE` completion rule.

By default, the loop prints the agent's messages and, for Claude, one line per
tool call (for example `> Bash quarto render slides.qmd`), filtered from its
JSON stream with `jq`. Each iteration ends with a summary (turns, minutes, cost)
and the build result. Add `--silent` to see only the iteration and build status
lines:

```bash
bash ralph.sh slides 5 --silent
```

The full agent output is always saved to `logs/run-*/iteration-N.log`. For
Claude this is newline-delimited JSON with all messages and tool results;
`reply.txt` holds only the final response used for the `DONE` check. Follow a
run in another terminal (replace the directory with the path printed at
startup):

```bash
tail -f logs/run-2026-11-15_14-30-00/iteration-1.log
```

## Start over

A new run continues from the existing `output/` and `PROGRESS.md`. To start
from scratch, delete the generated project, logs, and progress memory (copy
anything you want to keep first):

```bash
rm -rf output logs PROGRESS.md
```
