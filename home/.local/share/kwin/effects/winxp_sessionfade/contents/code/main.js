/*
    SPDX-License-Identifier: GPL-2.0-or-later

    While a window titled "WinXP Session Dialog" (the Windows XP Start Menu's
    Turn Off / Log Off dialog) is open, every other window - desktop and
    panels included - slowly loses its colour and dims a little, like XP.
*/
"use strict";

const marker = "WinXP Session Dialog";
const fadeIn = 1500;
const fadeOut = 250;

const sessionFade = {
    dialogs: [],
    animations: new Map(),

    isDialog(window) {
        return window && window.caption === marker;
    },

    fade(window) {
        if (this.isDialog(window) || this.animations.has(window) || window.deleted) {
            return;
        }
        // An animation paints its window, so leave out the ones not shown
        // (minimized, on another desktop or activity)
        if (!window.visible) {
            return;
        }
        const id = set({
            window: window,
            duration: fadeIn,
            animations: [
                { type: Effect.Saturation, to: 0.0 },
                { type: Effect.Brightness, to: 0.85 }
            ]
        });
        this.animations.set(window, { id: id, start: Date.now() });
    },

    restore() {
        const now = Date.now();
        for (const [window, entry] of this.animations) {
            cancel(entry.id);
            if (!window.deleted) {
                // Start from wherever the fade-in got to, not from full grey
                const progress = Math.min(1, (now - entry.start) / fadeIn);
                animate({
                    window: window,
                    duration: fadeOut,
                    animations: [
                        { type: Effect.Saturation, from: 1.0 - progress, to: 1.0 },
                        { type: Effect.Brightness, from: 1.0 - 0.15 * progress, to: 1.0 }
                    ]
                });
            }
        }
        this.animations.clear();
    },

    dialogShown(window) {
        this.dialogs.push(window);
        effects.stackingOrder.forEach(w => this.fade(w));
    },

    dialogHidden(window) {
        this.dialogs = this.dialogs.filter(w => w !== window);
        if (this.dialogs.length === 0) {
            this.restore();
        }
    },

    init() {
        effects.windowAdded.connect(window => {
            if (this.isDialog(window)) {
                this.dialogShown(window);
            } else if (this.dialogs.length > 0) {
                this.fade(window);
            }
        });
        effects.windowClosed.connect(window => {
            if (this.isDialog(window)) {
                this.dialogHidden(window);
            } else if (this.animations.has(window)) {
                // set() keeps the window alive until cancelled
                cancel(this.animations.get(window).id);
                this.animations.delete(window);
            }
        });
    }
};

sessionFade.init();
