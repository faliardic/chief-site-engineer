# Step 205 Learning - Canonical Instructions and Repository Truth

- A local-only high-priority instruction source needs a tracked canonical counterpart for fresh clones and handoffs.
- Source priority is safest when source path, canonical destination, SHA-256, and text-equivalence evidence are explicit.
- GitHub is the review surface; branch creation, file edits, verification, commit, and push remain official-local-first.
- README and machine-readable state must describe the latest merged safe point, not the last branch that happened to edit them.
- Workflow presence, automatic Actions execution, and required status checks are three separate facts and must not be conflated.
- Product maturity claims should list missing production capabilities plainly; a tested domain core is not a field-ready application.
- A next product direction can be recorded without starting implementation or widening the current documentation/state scope.
- Local-only sources and ignored emergency ZIP artifacts should be verified by hash and metadata without being staged or committed.
