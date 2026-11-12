# Minimal Ralph loop for accounting research

Edit `BRIEF.md`, add your sources/data to this folder, then run:

```bash
bash ralph.sh paper 5
bash ralph.sh slides 5
bash ralph.sh both 5
```

Requires an already configured Codex CLI, Bash, pdflatex, and biber. Each
iteration uses your configured Codex model and consumes its normal usage.

The loop starts a fresh Codex invocation with the same prompt each time.
It improves files, records its memory in `PROGRESS.md`, and gets the previous
build errors on the next pass. The shell compiles the requested documents.
It stops when the agent replies exactly `DONE` and compilation succeeds,
or when the iteration limit is reached. Each pass is one agent invocation;
the limit does not bound its duration or token usage.

Results live in `output/`; execution and build logs live in `logs/`.
Run again to continue existing work. Stop with Ctrl-C. Run only one loop
at a time in this folder. To start another project, use a separate copy.

The included brief produces a proposal. For an empirical paper, supply real
data, analyses, and verified literature, and change the completion requirements.
`DONE` is the agent's assessment plus a successful build; academic quality
and factual accuracy still require human review.

CLI invocation follows the [official OpenAI documentation](https://learn.chatgpt.com/docs/non-interactive-mode)
and was checked against the installed CLI's help.
