# Docs

The living documentation for this project. It ships **in the PR**, not as a follow-up — a reviewer reads the docs diff alongside the code diff.

- [`tech-dna.md`](tech-dna.md) — the coding genome: canonical, copy-me patterns. Read before writing any code.
- [`decisions/`](decisions/README.md) — ADRs: the "why" behind significant technical choices (immutable; superseded, never edited).
- [`architecture/`](architecture/README.md) — the "what": per-subsystem detail, one numbered file per area.
- [`runbooks/`](runbooks/) — step-by-step operational procedures (release, keystore, push setup, …).
- [`superpowers/`](superpowers/) — per-feature `plans/` (task breakdown) + `specs/` (rebuild docs) produced by `/feature`.
- [`glossary.md`](glossary.md) — domain + project terms.

See [`architecture/18-ai-dev-workflow.md`](architecture/18-ai-dev-workflow.md) for how the tech-DNA, the `/feature` / `/fix` commands, and the enforcement hooks fit together.
