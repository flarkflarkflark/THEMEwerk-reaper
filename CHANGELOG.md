# Changelog

## v0.1.7 - Toolbar Icon Refresh

- Refreshed the THEMEwerk toolbar icon family with the approved big-T/theme-tile design.
- Improved small-size readability, especially at 30x30 REAPER toolbar size.
- Added/updated toolbar icon sizes and strips used by ReaPack/REAPER.
- No runtime behavior changes.

## [Unreleased]

### Changed
- Updated THEMEwerk toolbar icon family with approved polished assets for improved 30x30 readability.

## [0.1.6] - 2026-05-07

### Changed
- Fix ReaPack file ownership conflict for toolbar icon installer

## [0.1.5] - 2026-05-07

### Changed
- Add install/uninstall toolbar icon actions and versioned popup titles

## [0.1.4] - 2026-05-07

### Changed
- Window title now uses auto-detected app version

## [0.1.3] - 2026-05-07

### Fixed
- Window title now auto-detects version from `THEMEwerk.lua` `@version`.
- Version metadata consistency for ReaPack release.

## [0.1.2] - 2026-05-07

### Added
- Toolbar icon pack for THEMEwerk in multiple sizes.
- ReaPack packaging entries for toolbar icon assets.
- README instructions for assigning THEMEwerk toolbar icons in REAPER.

## [0.1.0-alpha] - 2026-03-16

### Added
- Initial public alpha release.
- Live-apply theme browsing (mouse click or keyboard navigation).
- Support for `.ReaperTheme` and `.ReaperThemeZip`.
- Live synchronization of `ColorThemes` directory (detect adds/removals).
- Theme status tracking: **START**, **ACTIVE**, **NEW**, **MISSING**.
- Dynamic UI scaling (`+`, `-`, `0`).
- Persistent window geometry and scroll position.
- Compact metadata display.
- Branded "flarkAUDIO" footer with contextual help tooltips.
- Scrollbar indicator for the theme list.
- MIT License.
