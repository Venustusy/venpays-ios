# Deprecation Policy

## Semantic versioning

VenPaysApplePay follows semantic versioning:

- **MAJOR:** breaking public API or required backend contract changes incompatible with prior majors
- **MINOR:** backward-compatible features
- **PATCH:** backward-compatible fixes

Current series: **0.y.z** — public API may still evolve more aggressively than a post-1.0 commitment, but changes should be documented in CHANGELOG.

## Public API compatibility expectations

Public API is anything marked `public` under `Sources/VenPaysApplePay`.

Internal types may change without notice.

## Deprecation annotation policy

When removing or renaming public API after 1.0.0:

1. Mark with `@available(*, deprecated, message: "...")` (or renamed rename attribute).
2. Document in CHANGELOG and Release Notes.
3. Provide migration notes.

## Minimum notice target

**Proposed** (not formally approved): retain deprecated symbols for at least **one minor** release after announcement, except for emergency security removals.

## Emergency security exceptions

Security defects may justify immediate removal or behavior changes without a deprecation window. Document the exception in CHANGELOG and SecurityModel updates.

## Migration documentation requirement

Breaking changes require:

- CHANGELOG entry
- Release notes upgrade section
- APIReference / IntegrationGuide updates in the same PR when practical
