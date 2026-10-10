# Windows XP Start Menu for KDE Plasma 6

A Plasma 6 widget that replaces the application launcher with a replica of the
Windows XP (Luna, blue) start button and start menu. It is meant to go with XP
style Plasma themes such as [Exposé](https://www.opencode.net/phob1an/expose),
where the stock Kickoff/Kicker menus look out of place.

| Start menu | All Programs |
| --- | --- |
| ![Start menu](docs/preview-menu.png) | ![All Programs](docs/preview-all-programs.png) |

*Shown on the [Exposé](https://www.opencode.net/phob1an/expose) theme by phob1an
(its wallpaper and 38 px taskbar, GPL-2.0+). Rendered offscreen with placeholder
programs; the icons come from a stand-in icon theme instead of Exposé's DamaDamas.*

Exposé's selection colour (`#326AC4`) matches the Luna highlight the menu uses,
so the menu fits the theme without changes.

## Features

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
- Log Off and Turn Off Computer open Plasma's session dialogs.

## Installation

Requires Plasma 6.

```sh
git clone https://github.com/MArpogaus/kde-plasma-winxp-launcher.git
cd kde-plasma-winxp-launcher
./install.sh
```

Then right-click the existing application launcher → *Show Alternatives…* →
*Windows XP Start Menu*, or add it via *Add Widgets…*.

To remove: `kpackagetool6 --type Plasma/Applet --remove com.github.marpogaus.winxpstartmenu`

### Fonts

XP uses **Tahoma** in the menu and **Franklin Gothic Medium** on the start
button. If they are not installed the widget falls back to bundled look-alikes:
Wine's metric-compatible Tahoma (LGPL) and Libre Franklin (OFL); see
`package/contents/fonts`. Installing the original Tahoma gives the authentic
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
- All artwork in `package/contents/images` is original and licensed with the
  rest of the project. No Microsoft assets are included.

## License

GPL-2.0-or-later
