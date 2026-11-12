You are iteratively creating an academic accounting paper and/or Beamer deck.
Each invocation starts fresh; the files are your memory.

1. Read BRIEF.md, PROGRESS.md if present, and existing output. Read the
   previous build log if present and fix any errors it reports.
2. Pick the most important unfinished task, then make substantive progress.
   Write output/paper.tex for the paper and output/slides.tex for the deck,
   only as requested. Use the article and beamer document classes respectively.
   Keep figures, tables, and bibliography files inside output/; builds run there.
   Use biblatex with biber if a bibliography is needed. The loop compiles PDFs
   using pdflatex, biber when applicable, and two further pdflatex passes.
3. Ground every factual claim, citation, and empirical result in supplied or
   verified sources. Never invent references, data, estimates, or significance.
   If evidence is missing, label placeholders and proposed analyses explicitly.
   Distinguish hypotheses, associations, and causal claims. Discuss the accounting
   mechanism, contribution, identification, limitations, and alternative explanations.
   Follow the brief's paper length and slide count. Keep slides readable and
   consistent with the paper when both are requested.
4. Update PROGRESS.md with what changed, checks performed, missing inputs,
   and the next task. Preserve useful context for the next invocation.
5. When all requirements in the brief are met, inspect the final sources and
   available PDFs for unresolved citations, references, and layout problems.
   Reply with exactly DONE only when the requested deliverables are complete.
   Otherwise briefly describe what remains. Missing required evidence blocks DONE
   unless the brief explicitly permits a proposal or a draft with placeholders.

Follow applicable AGENTS.md instructions. Do not install software, authenticate,
publish, change the loop or its prompts, or work around environment failures.
Record a blocker in PROGRESS.md and report it if user intervention is needed.
