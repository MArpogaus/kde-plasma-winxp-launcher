# Windows XP for KDE Plasma 6

A one-click transformation pack that turns a Plasma 6 desktop into Windows XP
(Luna, blue): start button and start menu, taskbar, notification area,
Turn Off / Log Off dialogs with the grey screen fade, XP icons, cursors, fonts,
sounds, window borders, Bliss and a Dolphin set up like XP's Explorer.

```sh
git clone https://github.com/MArpogaus/kde-plasma-winxp-launcher.git
cd kde-plasma-winxp-launcher
./install.sh            # undo with ./install.sh --uninstall
```

| Start menu | All Programs |
| --- | --- |
| ![Start menu](docs/preview-menu.png) | ![All Programs](docs/preview-all-programs.png) |

*Shown on the [Exposé](https://www.opencode.net/phob1an/expose) theme by phob1an
(its wallpaper and 38 px taskbar, GPL-2.0+). Rendered offscreen with placeholder
programs; the icons come from a stand-in icon theme instead of Exposé's DamaDamas.*

Exposé's selection colour (`#326AC4`) matches the Luna highlight the menu uses,
so the menu fits the theme without changes.

## What the pack installs

| Part | Source |
| --- | --- |
| Start menu, taskbar, notification area, clock, Turn Off / Log Off dialogs | this repository (`plasmoids/`) |
| Grey screen fade behind the dialogs (KWin effect) | this repository (`kwin/sessionfade`) |
| Plasma theme, window borders, Kvantum application style, colours, splash, login screen | [Exposé](https://www.opencode.net/phob1an/expose) by phob1an |
| XP icons (original bitmaps), XP fonts, XP wallpapers, start flag | [xfce-winxp-tc](https://github.com/rozniak/xfce-winxp-tc) |
| Fallback icons for KDE-only names (traced XP style), Bliss in 4K | [KDE Plasma Luna](https://github.com/klapeto/KDE-Plasma-Luna) |
| Cursors (HiDPI) | [modernXP](https://github.com/na0miluv/modernXP-cursor-theme), or xfce-winxp-tc's XP cursors if neither `rsvg-convert` nor Inkscape is installed |
| Sounds | [Windows XP Sound Theme](https://github.com/wonordel/Windows-XP-Sound-Theme-KDE) |

How `install.sh` works:

1. **Downloads everything first.** If any resource is unavailable it stops and
   nothing on the system has been changed.
2. Builds the cursor theme (`tools/xcursor.py`, a byte-compatible replacement
   for xcursorgen), the icon theme (`tools/build-icon-theme.py`; XP icons
   first, then Luna, then Breeze) and Dolphin's XP toolbar
   (`tools/patch-dolphin-ui.py`, for your Dolphin version).
3. Backs up the configuration files it changes (first run only).
4. Installs everything into your home directory.
5. Applies it: colours, Plasma theme, icons, cursors, Kvantum style, window
   borders and XP button layout, Tahoma / Trebuchet MS fonts, double click,
   sounds, splash screen, Dolphin, and replaces the bottom panel with a 30 px
   XP taskbar (`layout/xp-desktop.js`) on Bliss.

Options: `--with-sddm` (login screen, needs sudo), `--no-panel` (keep your
panels), `--no-dolphin`, `--icons FILE|URL` (any icon theme archive, e.g. one
downloaded from store.kde.org), `--uninstall`.

Requirements: Plasma 6, git, python3, curl. Recommended: Kvantum (application
style) and `rsvg-convert` (HiDPI cursors).

Fonts, sounds and bitmaps that come from Windows are (C) Microsoft Corp. The
installer downloads them from their upstream projects on your machine; this
repository contains none of them.

### Dolphin as XP Explorer

Toolbar *Back · Forward · Up | Search · Folders | Views* with labels on Back,
Search and Folders, the address bar on its own row, menu bar and status bar on,
48 px "tiles" with type and size, folders first, double click. Press F7 (or
*Folders*) once to show the folder tree; Dolphin remembers it. XP's blue task
pane on the left has no Dolphin counterpart; the Places panel takes its spot.

## Widgets only

```sh
./install-widgets.sh
```

installs the four widgets (*Windows XP Start Menu*, *Windows XP Taskbar*,
*Windows XP Notification Area*, *Windows XP Clock*) and the fade effect
without changing anything else. For the XP taskbar look, add them in this
order to a 30 px bottom panel: Start Menu, Taskbar, Notification Area,
System Tray, Clock. The Notification Area paints the light blue block under
everything to its right.

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
button. If they are not installed the widget falls back to bundled look-alikes:
Wine's metric-compatible Tahoma (LGPL) and Libre Franklin (OFL); see
`plasmoids/startmenu/contents/fonts`. Installing the original Tahoma gives the authentic
bold weight. Both fonts are configurable in the widget settings.

## Configuration

Right-click the start button → *Configure Windows XP Start Menu…*

- button label, icon (empty = built-in flag) and fonts
- number of frequently used programs; which optional entries of the right
  column are shown (My Recent Documents, My Pictures, My Music, My Network
  Places, Set Program Access and Defaults, Printers and Faxes), like XP's
  *Customize Start Menu* dialog
- the location or command behind every entry of the right column
  (My Computer, Control Panel, Printers and Faxes, Help and Support, Search, Run…)

## Notes

- Uses Plasma's private `org.kde.plasma.private.kicker` models (as Kickoff,
  Kicker and many third-party launchers do), so pinned programs and usage
  statistics come from KActivities.
- All artwork in `plasmoids/startmenu/contents/images` is original and licensed with the
  rest of the project. No Microsoft assets are included.

## License

GPL-2.0-or-later
