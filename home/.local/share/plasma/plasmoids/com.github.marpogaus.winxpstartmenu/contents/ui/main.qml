/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP style start menu for Plasma 6.

    The menu is not shown through Plasma's applet popup (which would wrap
    it in the Plasma theme's frame) but in its own frameless window, so
    every pixel is drawn by StartMenu.qml.
*/
import QtQuick
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker
import org.kde.coreaddons as KCoreAddons

PlasmoidItem {
    id: root

    readonly property XpTheme xp: XpTheme {
        fontFamily: Plasmoid.configuration.fontFamily
        startFontFamily: root.fontInstalled(Plasmoid.configuration.startFontFamily)
                         ? Plasmoid.configuration.startFontFamily : "Libre Franklin"
    }

    // Bundled look-alikes for the non-free XP fonts. Tahoma (Wine, LGPL) is
    // only registered when no real Tahoma is installed, and only its regular
    // face (Wine's bold renders with regular-weight outlines, so Qt makes
    // the bold one up). Libre Franklin (OFL) stands in for Franklin Gothic
    // Medium.
    readonly property var installedFonts: Qt.fontFamilies()

    function fontInstalled(family) {
        return installedFonts.indexOf(family) >= 0;
    }

    FontLoader { source: root.fontInstalled("Tahoma") ? "" : Qt.resolvedUrl("../fonts/tahoma.ttf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/LibreFranklin-Bold.ttf") }

    // Start icon: the configured one, else XP's original 20 px flag if
    // get-microsoft-files.sh put it in place, else the bundled flag ("")
    readonly property string startIcon: Plasmoid.configuration.startIcon
        || (xpFlag.status === Image.Ready ? xpFlag.source.toString() : "")

    Image {
        id: xpFlag
        visible: false
        source: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/winxp-kde/start_flag.png"
    }

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool menuOpen: false
    property double lastClosed: 0
    property bool contextMenuOpen: false
    property var cascades: []

    // The button itself is the (inline) full representation, so Plasma never
    // opens its own popup; `expanded` just mirrors our menu window.
    preferredRepresentation: fullRepresentation
    compactRepresentation: null
    fullRepresentation: StartButton {
        xp: root.xp
        controller: root
        vertical: root.vertical
        fillPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        text: Plasmoid.configuration.startText
        iconName: root.startIcon
    }

    toolTipMainText: i18n("Click here to begin")
    toolTipSubText: ""
    Plasmoid.icon: "start-here-kde"
    Plasmoid.status: menuOpen ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    // The global shortcut (Meta) toggles `expanded`.
    onExpandedChanged: {
        if (expanded !== menuOpen) {
            if (expanded) {
                openMenu();
            } else {
                closeMenu();
            }
        }
    }

    // ------------------------------------------------------------------
    // Data models (shared with Kicker / Kickoff)
    // ------------------------------------------------------------------
    Kicker.RootModel {
        id: rootModel

        autoPopulate: false
        appletInterface: root
        appNameFormat: 0
        flat: false
        sorted: true
        showSeparators: false
        showAllApps: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false

        Component.onCompleted: {
            favoritesModel.initForClient("com.github.marpogaus.winxpstartmenu.favorites.instance-" + Plasmoid.id);
            if (!Plasmoid.configuration.favoritesInitialized) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(["preferred://browser", "preferred://mail"]);
                }
                Plasmoid.configuration.favoritesInitialized = true;
            }
            rootModel.refresh();
        }
    }

    Kicker.RecentUsageModel {
        id: frequentModel
        favoritesModel: rootModel.favoritesModel
        ordering: 1 // most used first
        shownItems: Kicker.RecentUsageModel.OnlyApps
    }

    Kicker.RecentUsageModel {
        id: recentDocsModel
        favoritesModel: rootModel.favoritesModel
        ordering: 0 // most recent first
        shownItems: Kicker.RecentUsageModel.OnlyDocs
    }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: root
        favoritesModel: rootModel.favoritesModel
        mergeResults: true
        runners: ["krunner_services", "krunner_systemsettings", "krunner_sessions", "krunner_powerdevil",
                  "calculator", "unitconverter", "locations", "baloosearch", "krunner_recentdocuments"]
        query: startMenu.searchText
    }

    KCoreAddons.KUser {
        id: kuser
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: sourceName => disconnectSource(sourceName)

        property int launches: 0

        // A source stays connected until its process exits and connecting
        // it again is a no-op, so a second click on e.g. Help and Support
        // while the first one still runs would do nothing. A trailing
        // comment line makes every launch a new source.
        function exec(command) {
            if (command && command.length > 0) {
                connectSource(command + "\n# " + (++launches));
            }
        }
    }

    // ------------------------------------------------------------------
    // Windows
    // ------------------------------------------------------------------
    PlasmaCore.Dialog {
        id: menuDialog

        visible: false
        type: PlasmaCore.Dialog.AppletPopup
        flags: Qt.WindowStaysOnTopHint
        location: Plasmoid.location
        // Above the visible taskbar, not the applet area inside its padding
        visualParent: root.fullRepresentationItem ? root.fullRepresentationItem.faceItem : null
        hideOnWindowDeactivate: false

        onActiveChanged: root.checkActivation()
        onVisibleChanged: {
            if (!visible && root.menuOpen) {
                root.closeMenu();
            }
        }

        Component.onCompleted: {
            if ("backgroundHints" in menuDialog) {
                menuDialog.backgroundHints = PlasmaCore.Dialog.NoBackground;
            }
        }

        mainItem: StartMenu {
            id: startMenu
            xp: root.xp
            controller: root
            favoritesModel: rootModel.favoritesModel
            frequentModel: frequentModel
            searchModel: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
            numFrequentApps: Plasmoid.configuration.numFrequentApps
            hiddenPlaces: Plasmoid.configuration.hiddenPlaces
            userName: kuser.fullName || kuser.loginName
            userAvatar: kuser.faceIconUrl
        }
    }

    Component {
        id: cascadeComponent
        CascadeMenu {}
    }

    Component {
        id: contextMenuComponent
        PlasmaExtras.Menu {
            id: contextMenu
            onStatusChanged: {
                if (status === PlasmaExtras.Menu.Closed) {
                    root.contextMenuOpen = false;
                    root.checkActivation();
                    contextMenu.destroy(1000);
                }
            }
        }
    }

    Component {
        id: contextMenuItemComponent
        PlasmaExtras.MenuItem {
            property var handler: null
            onClicked: if (handler) handler()
        }
    }

    // Close everything once focus has left all of our windows. The check is
    // deferred so that focus moving between the menu and a cascade does not
    // count as leaving.
    Timer {
        id: activationCheck
        interval: 150
        onTriggered: {
            if (root.menuOpen && !root.anyWindowActive()) {
                root.closeMenu();
            }
        }
    }

    // ------------------------------------------------------------------
    // Controller API used by StartButton, StartMenu and CascadeMenu
    // ------------------------------------------------------------------
    // The screen area free of panels, in global coordinates (cascades stay
    // inside it)
    readonly property rect availableArea: availableScreenRect.width > 0
        ? Qt.rect(screenGeometry.x + availableScreenRect.x, screenGeometry.y + availableScreenRect.y,
                  availableScreenRect.width, availableScreenRect.height)
        : screenGeometry

    // Dragging an application out of the menu (Kicker's helper starts the
    // drag from this item: cascades may be gone before it ends)
    Kicker.DragHelper {
        id: dragHelper
        dragIconSize: 32
        onDropped: root.closeMenu()
    }

    function startDrag(url, icon) {
        dragHelper.startDrag(root, url, icon);
    }

    function anyWindowActive() {
        if (menuDialog.active || contextMenuOpen) {
            return true;
        }
        return cascades.some(c => c && c.active);
    }

    function checkActivation() {
        activationCheck.restart();
    }

    function menuOpenOrJustClosed() {
        return menuOpen || (Date.now() - lastClosed) < 300;
    }

    function openMenu() {
        if (menuOpen) {
            return;
        }
        startMenu.reset();
        menuOpen = true;
        expanded = true;
        menuDialog.visible = true;
        menuDialog.requestActivate();
        startMenu.forceActiveFocus();
    }

    function closeMenu() {
        if (!menuOpen) {
            return;
        }
        menuOpen = false;
        expanded = false;
        lastClosed = Date.now();
        closeCascadesFrom(0);
        menuDialog.visible = false;
        startMenu.searchText = "";
    }

    function maxCascadeRows() {
        // Leave room for the panel; long menus wrap into more columns.
        const screenHeight = startMenu.screenHeight > 0 ? startMenu.screenHeight : 768;
        return Math.max(5, Math.floor((screenHeight - 56) / xp.cascadeRowHeight));
    }

    // bottomAlign: grow upwards from visualParent's bottom edge (All Programs);
    // otherwise the cascade's first row is level with visualParent.
    function openCascade(level, visualParent, model, ownerView, ownerIndex, bottomAlign) {
        closeCascadesFrom(level);
        if (!model || !visualParent) {
            return null;
        }
        const cascade = cascadeComponent.createObject(root, {
            xp: root.xp,
            controller: root,
            model: model,
            level: level,
            maxRows: maxCascadeRows(),
            // keeps it stacked above the menu (or the cascade it came from)
            transientParent: level > 0 && cascades[level - 1] ? cascades[level - 1] : menuDialog,
        });
        // Next to the cascade the row is in, or to the start menu itself;
        // All Programs grows up from its button instead
        cascade.placeAt(visualParent, ownerView ? ownerView.frameItem : bottomAlign ? null : startMenu);
        cascade.visible = true;
        const list = cascades.slice(0, level);
        list[level] = cascade;
        cascades = list;
        if (ownerView) {
            ownerView.openIndex = ownerIndex;
        }
        return cascade;
    }

    function closeCascadesFrom(level) {
        if (cascades.length <= level) {
            return;
        }
        let hadFocus = false;
        for (let i = cascades.length - 1; i >= level; --i) {
            const cascade = cascades[i];
            if (cascade) {
                hadFocus = hadFocus || cascade.active;
                cascade.visible = false;
                cascade.destroy();
            }
        }
        cascades = cascades.slice(0, level);
        // Don't let focus fall out of the menu when a focused cascade closes.
        if (hadFocus && menuOpen) {
            menuDialog.requestActivate();
        }
        if (level === 0) {
            startMenu.openCascade = "";
        } else if (cascades[level - 1]) {
            cascades[level - 1].view.openIndex = -1;
        }
    }

    function openAllPrograms(item) {
        if (openCascade(0, item, rootModel, null, -1, true)) {
            startMenu.openCascade = "programs";
        }
    }

    function openRecentDocuments(item) {
        if (openCascade(0, item, recentDocsModel, null, -1)) {
            startMenu.openCascade = "recent";
        }
    }

    function isPinned(favoriteId) {
        const favorites = rootModel.favoritesModel;
        return !!favoriteId && !!favorites && favorites.isFavorite(favoriteId);
    }

    function launchFavorite(index) {
        rootModel.favoritesModel.trigger(index, "", null);
        closeMenu();
    }

    function launchFrequent(row) {
        frequentModel.trigger(row, "", null);
        closeMenu();
    }

    function launchSearchResult(index) {
        const results = startMenu.searchModel;
        if (results && index >= 0 && index < results.count) {
            results.trigger(index, "", null);
            closeMenu();
        }
    }

    function openUrl(url) {
        Qt.openUrlExternally(url);
        closeMenu();
    }

    function runCommand(command) {
        executable.exec(command);
        closeMenu();
    }

    function openPlace(key) {
        const cfg = Plasmoid.configuration;
        switch (key) {
        case "documents":
            return openUrl(StandardPaths.writableLocation(StandardPaths.DocumentsLocation));
        case "pictures":
            return openUrl(StandardPaths.writableLocation(StandardPaths.PicturesLocation));
        case "music":
            return openUrl(StandardPaths.writableLocation(StandardPaths.MusicLocation));
        case "computer":
            return openUrl(cfg.myComputerUrl);
        case "network":
            return openUrl(cfg.networkUrl);
        case "controlpanel":
            return runCommand(cfg.controlPanelCommand);
        case "defaults":
            return runCommand(cfg.defaultsCommand);
        case "printers":
            return runCommand(cfg.printersCommand);
        case "help":
            return runCommand(cfg.helpCommand);
        case "search":
            return runCommand(cfg.searchCommand);
        case "run":
            return runCommand(cfg.runCommand);
        }
    }

    // XP's own Turn Off / Log Off dialogs; the actions go straight to the
    // session manager, so Plasma's confirmation screen is not shown again.
    SessionDialog {
        id: sessionDialog
        xp: root.xp
        flagIcon: root.startIcon
        screenGeometry: Plasmoid.containment.screenGeometry
        onActivated: action => root.sessionAction(action)
    }

    readonly property var sessionCommands: ({
        standby: "dbus-send --system --type=method_call --dest=org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true",
        turnoff: "dbus-send --session --type=method_call --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndShutdown",
        restart: "dbus-send --session --type=method_call --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot",
        logoff: "dbus-send --session --type=method_call --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logout",
        switchuser: "dbus-send --session --type=method_call --dest=org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.openSwitchUserDialog"
    })

    function sessionAction(action) {
        if (sessionCommands[action]) {
            executable.exec(sessionCommands[action]);
        }
    }

    function logOff() {
        closeMenu();
        sessionDialog.open("logoff");
    }

    function turnOff() {
        closeMenu();
        sessionDialog.open("turnoff");
    }

    // The Quick Launch widget in the same panel, if there is one
    function quickLaunch() {
        const applets = Plasmoid.containment ? Plasmoid.containment.applets : [];
        for (let i = 0; i < applets.length; ++i) {
            if (applets[i].pluginName === "com.github.marpogaus.winxpquicklaunch") {
                return applets[i];
            }
        }
        return null;
    }

    // XP's context menus have no icons
    function showItemContextMenu(model, index, favoriteId, actionList, visualParent, x, y) {
        if (!model) {
            return;
        }
        const entries = [];
        const favorites = rootModel.favoritesModel;

        entries.push({ text: i18n("Open"), handler: () => {
            model.trigger(index, "", null);
            closeMenu();
        } });

        if (favoriteId && favorites) {
            entries.push({ separator: true });
            if (favorites.isFavorite(favoriteId)) {
                entries.push({ text: i18n("Unpin from Start menu"), handler: () => {
                    favorites.removeFavorite(favoriteId);
                } });
            } else {
                entries.push({ text: i18n("Pin to Start menu"), handler: () => {
                    favorites.addFavorite(favoriteId, -1);
                } });
            }
        }

        const quickLaunchApplet = favoriteId ? quickLaunch() : null;
        if (quickLaunchApplet) {
            // Quick Launch takes the launcher URLs the Task Manager uses
            const url = favoriteId.startsWith("/") ? "file://" + favoriteId
                : favoriteId.includes(":") ? favoriteId : "applications:" + favoriteId;
            const config = quickLaunchApplet.configuration;
            // Handlers re-read the list: it may change while the menu is open
            if (Array.from(config.launchers).includes(url)) {
                entries.push({ text: i18n("Remove from Quick Launch"), handler: () => {
                    config.launchers = Array.from(config.launchers).filter(launcher => launcher !== url);
                } });
            } else {
                entries.push({ text: i18n("Add to Quick Launch"), handler: () => {
                    const launchers = Array.from(config.launchers);
                    if (!launchers.includes(url)) {
                        config.launchers = launchers.concat([url]);
                    }
                } });
            }
        }

        actionList = actionList ? Array.from(actionList) : [];
        if (actionList.length > 0) {
            entries.push({ separator: true });
            actionList.forEach(action => {
                if (action.type === "separator") {
                    entries.push({ separator: true });
                } else if (action.type !== "title" && !action.subActions) {
                    entries.push({ text: action.text, handler: () => {
                        if (model.trigger(index, action.actionId, action.actionArgument)) {
                            closeMenu();
                        }
                    } });
                }
            });
        }

        const menu = contextMenuComponent.createObject(root, { visualParent: visualParent });
        entries.forEach(entry => {
            contextMenuItemComponent.createObject(menu, {
                text: entry.text ?? "",
                separator: entry.separator === true,
                handler: entry.handler ?? null,
            });
        });
        contextMenuOpen = true;
        menu.open(x, y);
    }
}
