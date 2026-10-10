# Windows XP for KDE Plasma 6

Turns a Plasma 6 desktop into Windows XP (Luna, blue): start button and
start menu, taskbar, notification area, Turn Off / Log Off dialogs with the
grey screen fade, XP Alt+Tab, Luna icons, XP cursors, Exposé window borders
and application style, and Dolphin set up like XP's Explorer.

| Start menu | All Programs |
| --- | --- |
| ![Start menu](docs/preview-menu.png) | ![All Programs](docs/preview-all-programs.png) |

## Install

Everything lives in `home/` at the place it belongs in your home directory.

```sh
git clone https://github.com/MArpogaus/kde-plasma-winxp-launcher.git
cd kde-plasma-winxp-launcher
cp -r home/. ~
```

Then *System Settings → Colors & Themes → Global Theme → Windows XP*, tick
*Use desktop layout from theme*, and *Apply*. Log out and back in once.

This applies the Exposé colours, Plasma theme, window borders and Kvantum
style, Luna icons, modernXP cursors, the XP Alt+Tab switcher, the Exposé
splash screen and wallpaper, and replaces your panels with a 30 px XP
taskbar: Start, task buttons, notification area, system tray, clock.

Requirements: Plasma 6; [Kvantum](https://github.com/tsujan/Kvantum) for the
application style (without it applications fall back to Fusion).

Copying overwrites Dolphin's toolbar (`~/.local/share/kxmlgui5/dolphin/dolphinui.rc`),
Dolphin's default view and Kvantum's theme choice (`~/.config/Kvantum/kvantum.kvconfig`).

### Original XP files (optional)

XP's fonts, original icons, sounds, Bliss and the original start flag belong
to Microsoft, so they are not part of this repository.
`./get-microsoft-files.sh` downloads them from
[xfce-winxp-tc](https://github.com/rozniak/xfce-winxp-tc) and
[Windows-XP-Sound-Theme-KDE](https://github.com/wonordel/Windows-XP-Sound-Theme-KDE),
and switches to the XP icons (falling back to Luna), Tahoma / Trebuchet MS,
the XP sounds and Bliss. The start button picks up XP's flag automatically.

### Login screen (optional)

Exposé's login screen is a system-wide SDDM theme; see
[Exposé](https://www.opencode.net/phob1an/expose) (`sddm/themes/expose`).

### Uninstall

Pick another Global Theme with *Use desktop layout from theme* ticked (so
no panel keeps the XP widgets), then remove the copied files and, if you ran
`get-microsoft-files.sh`, what it downloaded:

```sh
(cd home && git ls-files) | (cd ~ && xargs -d '\n' rm -f)
rm -rf ~/.local/share/{fonts,wallpapers,sounds}/WindowsXP \
       ~/.local/share/icons/WindowsXP-Luna ~/.local/share/winxp-kde
```

The XP fonts and sounds stay selected in *System Settings* until you pick
others there.

## What is in `home/`

| Part | Path | Source, license |
| --- | --- | --- |
| Start menu, taskbar, notification area, clock widgets | `.local/share/plasma/plasmoids/com.github.marpogaus.*` | this repository, GPL-2.0+ |
| Grey fade behind Turn Off / Log Off (KWin effect) | `.local/share/kwin/effects/winxp_sessionfade` | this repository, GPL-2.0+ |
| XP Alt+Tab (KWin window switcher) | `.local/share/kwin/tabbox/winxp_alttab` | this repository, GPL-2.0+ |
| Windows XP Global Theme (defaults, taskbar layout) | `.local/share/plasma/look-and-feel/com.github.marpogaus.winxp` | this repository; splash from Exposé, GPL-3.0 |
| Plasma theme, window borders, colours, Kvantum style, wallpaper | `desktoptheme/expose`, `aurorae/themes/Expose`, `color-schemes`, `.config/Kvantum`, `wallpapers/Expose` | [Exposé](https://www.opencode.net/phob1an/expose) by phob1an, GPL-3.0 (wallpaper CC BY-SA 4.0) |
| Luna icons (up to 128 px) | `.local/share/icons/Luna` | [KDE Plasma Luna](https://github.com/klapeto/KDE-Plasma-Luna) by klapeto, GPL-3.0 |
| Cursors | `.local/share/icons/ModernXP` | built from [modernXP](https://github.com/na0miluv/modernXP-cursor-theme), GPL-3.0 |
| Dolphin as XP Explorer | `.local/share/kxmlgui5/dolphin`, `.local/share/dolphin` | toolbar derived from [Dolphin](https://invent.kde.org/system/dolphin), GPL-2.0+ |

The third-party parts keep their licences (see the LICENSE files next to
them); because of them the bundle as a whole is distributed under GPL-3.0.
`tools/update-vendored.sh` refreshes them from upstream.

### Dolphin as XP Explorer

Toolbar *Back · Forward · Up | Search · Folders | Views* with labels on
Back, Search and Folders, the address bar on its own row, and tiles
(compact view) with type and size. Press Ctrl+M once for the menu bar, F7
for the folder tree and Ctrl++ until the tiles reach XP's 48 px icons;
Dolphin remembers all three. XP's blue task pane has no Dolphin
counterpart.

The toolbar file is made for the Dolphin release it was taken from; a newer
Dolphin with a changed toolbar file ignores it until
`tools/update-vendored.sh` refreshes it.

## Start menu features

- Green **start** button with flag, hover and pressed states, sized to the
  panel (99 × 30 px on a 30 px panel). Tooltip: "Click here to begin".
- Menu drawn pixel by pixel in its own frameless window (no Plasma dialog
  frame): rounded blue header with user picture and name, orange divider,
  white program column, light blue places column, Log Off / Turn Off Computer footer.
- Geometry and colours measured from real XP screenshots: 466 px wide,
  63 px header, 39 px footer, 40 px program rows with 32 px icons, 32 px place
  rows with 24 px icons. Header/footer gradients are sampled row by row.
- **Pinned programs** at the top (Internet and E-mail by default, using your
  preferred browser and mail client) and **most frequently used programs** below.
- **All Programs** cascading menus with hover-to-open delay, folder arrows and
  multi-column wrapping for long menus, just like XP.
- **My Recent Documents** cascade.
- Right-click on a program: Open, Pin to / Unpin from Start menu, plus the
  usual application actions (Edit Application, Add to Desktop, …).
- Type while the menu is open to search (KRunner backends); results replace
  the program list, Up/Down/Enter to launch, Esc to clear.
- Meta key opens the menu (it can replace Kickoff via *Show Alternatives*).
- Log Off and Turn Off Computer open XP style Log Off / Turn Off dialogs.

### Fonts

XP uses **Tahoma** in the menu and **Franklin Gothic Medium** on the start
button. If they are not installed the start menu falls back to bundled
look-alikes: Wine's metric-compatible Tahoma (LGPL) and Libre Franklin (OFL),
see the widget's `contents/fonts`. Both fonts are configurable.

## Configuration

Right-click the start button → *Configure Windows XP Start Menu…*

- button label, icon (empty = XP's flag if downloaded, else the built-in one) and fonts
- number of frequently used programs; which optional entries of the right
  column are shown, like XP's *Customize Start Menu* dialog
- the location or command behind every entry of the right column

## Development

- `tools/check-qml.py`: finds QML properties that shadow built-in ones
  (needs PySide6).
- `tools/update-vendored.sh`: refreshes the third-party files in `home/`.
- `tools/xcursor.py`, `tools/build-icon-theme.py`, `tools/patch-dolphin-ui.py`:
  helpers used by the two scripts.
- Edits to widgets: copy `home/` again and restart plasmashell
  (`systemctl --user restart plasma-plasmashell`).

The start menu uses Plasma's private `org.kde.plasma.private.kicker` models
(as Kickoff and Kicker do). All artwork of the widgets is original; no
Microsoft assets are included in this repository.

## License

This repository's own code: GPL-2.0-or-later. Bundled third-party files:
see the table above.
