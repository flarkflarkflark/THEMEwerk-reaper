<h1>
  <span style="color: #20c141;">THEME</span>werk
  <img src="assets/toolbar_icons/masters/themewerk_main.png" alt="THEMEwerk logo" width="64" style="vertical-align: middle; margin-left: 12px;">
</h1>

THEMEwerk is a live local theme browser for REAPER. Click a theme, see it instantly, and browse your ColorThemes folder without the usual menu diving.

<p align="center">
  <img src="docs/Screenshot.png" alt="THEMEwerk screenshot" width="50%"><br>
  <em>Current GFX UI with live-apply theme list.</em>
</p>

## Features

- **Instant Apply**: Themes are applied immediately as you click or navigate via keyboard.
- **Directory Sync**: Automatically detects new or removed themes while open.
- **Status Tracking**:
  - **START**: The theme active when you launched THEMEwerk.
  - **ACTIVE**: The theme currently active in REAPER.
  - **NEW**: Themes added during the session.
  - **MISSING**: Previously known themes no longer found on disk.
- **UI Scaling**: Fully continuous scaling system for any display size.
- **Zero Dependencies**: Pure Lua, using only native REAPER APIs.

## Installation

### Option 1 - Manual
1. Download the latest release.
2. Copy `THEMEwerk.lua` and the `lib/` folder into your REAPER `Scripts` directory.
3. Add `THEMEwerk.lua` via the REAPER Action List.

### Option 2 - ReaPack
1. Open REAPER.
2. Go to `Extensions -> ReaPack -> Import repositories...`
3. Paste this URL: `https://raw.githubusercontent.com/flarkflarkflark/THEMEwerk-reaper/master/index.xml`
4. Synchronize packages.
5. Install `THEMEwerk`.

## Controls

- **Click / Arrows**: Apply selected theme immediately.
- **Page Up / Down**: Jump through the list.
- **Home / End**: Go to the first or last theme.
- **R**: Revert to the session-start theme.
- **Mouse wheel**: Scroll list.
- **+ / - / 0**: UI scale up / down / reset.

## Toolbar Icon (THEMEwerk)

The repo includes a custom toolbar icon pack in multiple sizes:

- `assets/toolbar_icons/strips_90x30/themewerk_main_90x30.png`
- `assets/toolbar_icons/strips_135x45/themewerk_main_135x45.png`
- `assets/toolbar_icons/strips_180x60/themewerk_main_180x60.png`
- `assets/toolbar_icons/single/themewerk_main_24x24.png`
- `assets/toolbar_icons/single/themewerk_main_30x30.png`
- `assets/toolbar_icons/single/themewerk_main_36x36.png`
- `assets/toolbar_icons/single/themewerk_main_45x45.png`
- `assets/toolbar_icons/single/themewerk_main_48x48.png`
- `assets/toolbar_icons/single/themewerk_main_60x60.png`
- `assets/toolbar_icons/single/themewerk_main_64x64.png`
- `assets/toolbar_icons/masters/themewerk_main.png`

Compatibility alias (same as 90x30 strip):

- `assets/toolbar_icons/THEMEwerk_toolbar.png`

To use it in REAPER:

1. Run the action `THEMEwerk: Install Toolbar Icons` (installed via ReaPack).
2. Right-click your toolbar -> `Customize toolbar...`
3. Right-click the THEMEwerk action -> `Set button icon...`
4. Choose `themewerk_main_90x30.png` (or one of the other THEMEwerk strips).

The current toolbar icon family is tuned for clearer 30x30 readability with a stronger central THEMEwerk motif.

## Support

If THEMEwerk helps your workflow, you can support development here:

- **Ko-fi**: https://ko-fi.com/flarkaudio

## License

MIT License. See [LICENSE](LICENSE) for details.

---

Created by **flarkAUDIO**
