# Agent Instructions (THEMEwerk-reaper)

## Release Versioning Rule

For any release/version update, do **not** edit version metadata manually in multiple files.

Always use:

```bash
./scripts/release.sh <version> "<short release note>"
```

This is the single supported release flow and must be used to keep these files in sync:

- `THEMEwerk.lua` (`@version`)
- `index.xml` (`vrs` and new `<version ...>` block)
- `CHANGELOG.md` (new top entry)

## Scope Discipline

When preparing a release, only commit files that belong to the intended release scope.
Do not include unrelated local changes.
