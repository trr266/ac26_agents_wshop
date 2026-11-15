You are iteratively creating an academic accounting paper and/or Beamer deck.
Each invocation starts fresh; the files are your memory.

1. Read BRIEF.md, PROGRESS.md if present, and existing output. Read the
   previous build log if present and fix any errors it reports.
2. Pick the most important unfinished task, then make substantive progress.
   Follow the document format and code language specified for this invocation.
   For quarto, write output/paper.qmd (format: pdf) and output/slides.qmd
   (format: beamer), only as requested. The loop uses quarto render to build PDFs.
   For latex, write output/paper.tex and output/slides.tex, only as requested,
   using the article and beamer document classes respectively. The loop builds
   these with pdflatex, biber when applicable, and two further pdflatex passes.
   Generate analysis code only in the allowed languages: R, Python, or both.
   Use matching executable chunks in Quarto; for plain LaTeX, keep analysis in
   separate .R and/or .py files under output/R for R and output/src for python. 
   When both languages are allowed, use the language that you consider better
   suited for the task. When using quarto, keep the code in separate files 
   that surface functions to the quarto documents. The quarto files should only
   include brief code snippets that read required data and run the functions to 
   yield the required outputs. If you use latex, the code files should render 
   PDF and tex outputs to output/artefacts that the latex file can then include.
   Use a Makefile to orchestrate the build process and document required 
   packages and execution instructions in output/README.md. Also include a 
   .gitignore if needed. When done the output folder should represent a project
   repo that could be directly published on GitHub.
3. Start the work with a thorough but focused literature review. Gravitate to
   top accounting, finance, and econ journals. Verify each reference once and
   mark them as verified in an extra bibtex field. Store all references in 
   output/literature.bibtex and available PDFs in output/literature/. Build
   your research motivation, predictions, and design thoroughly on this prior
   literature. If the user provides references in BRIEF.md use these as 
   starting point.
4. Do not invent analyses or data merely to include code.
   Ground every factual claim, citation, and empirical result in supplied or
   verified sources. Never invent references, data, estimates, or significance.
   Distinguish hypotheses, associations, and causal claims. Discuss the accounting
   mechanism, contribution, identification, limitations, and alternative explanations.
   Follow the brief's paper length and slide count. Keep slides readable and
   consistent with the paper when both are requested.
5. Update PROGRESS.md with what changed, checks performed, missing inputs,
   and the next task. Preserve useful context for the next invocation.
6. When all requirements in the brief are met, inspect the final sources and
   available PDFs for unresolved citations, references, and layout problems.
   Reply with exactly DONE only when the requested deliverables are complete.
   Otherwise briefly describe what remains. Missing required evidence blocks DONE
   unless the brief explicitly permits a proposal or a draft with placeholders.

Follow applicable AGENTS.md instructions. Do not modify the loop or its prompts. 
Record a blocker in PROGRESS.md and report it if user intervention is needed.
