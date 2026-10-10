// SPDX-License-Identifier: GPL-2.0-or-later
//
// Paints the start button's face pixel by pixel: XP lights it from the top
// left, so its shading changes across both directions (a highlight along
// the top and the upper left, a brighter middle on the right end, darker
// corners) which gradients cannot reproduce.
.pragma library

// Colours of the XP start button's face (without flag and label), sampled
// from a 30 px tall button: one row per pixel row, columns at the given
// distance from the left edge (L), in the middle (M) or from the right
// edge (R). Edge pixels the taskbar showed through are rebuilt from inner
// ones.
var COLUMNS = [["L", 0], ["L", 1], ["L", 2], ["L", 3], ["L", 4], ["L", 6], ["L", 8], ["M", 0], ["R", 24], ["R", 20], ["R", 16], ["R", 14], ["R", 12], ["R", 10], ["R", 8], ["R", 6], ["R", 4], ["R", 3], ["R", 2]];
var ROWS = [
    "256e55 3c7e3e 438643 498a49 4c8b4c 4a8a4a 4a8a4a 4f9250 479047 468b46 438d44 448d44 408d41 3f8d3f 3e8a3e 337c37 2d742d 286928 255f25",
    "256c54 458b47 559b55 64a464 6fab6f 72ac72 71ac71 75af75 65a864 5fa55e 59a15a 59a159 539f53 509c50 4d9a4d 448e45 3c843c 357735 316b31",
    "277459 559957 68a868 79b479 8abd8a 95c395 95c395 8bbe8c 78b477 6fb26e 6aac69 67ab67 60a860 5ca55b 56a156 4e984e 458e45 3d803d 387438",
    "267056 589b5a 70af70 82ba82 8dbf8d 92c192 91c191 84b984 70b06f 6aad69 66ab66 61a962 5ca55c 56a256 529e51 4b964b 428c42 3b7f3b 377337",
    "236751 579a5a 76b076 88bc88 8abd8a 88bd88 85ba85 74af74 62aa61 5ea65d 59a359 55a255 519e50 4b9a4c 489747 439143 3b803e 347434 306930",
    "236751 579a5a 76b076 86bb86 85ba85 7bb87b 77b277 66a666 54a454 52a152 4c9c4c 499a4a 459645 419342 3e8f3d 3a8b3b 367d36 307130 2c662c",
    "236751 579a5a 74b074 7db87d 77b277 6cac6c 6baa6a 5aa05a 4b9f4a 479c47 439842 419542 3c903d 3a8d3a 368836 338333 2f7b30 2b7431 286928",
    "236751 579a5a 6cab6c 75b174 6eae6e 5fa05f 5ea15e 519b50 469d46 419941 3d953d 3c923c 388d39 358936 338333 307f2f 2c7b2c 2a732c 276827",
    "236751 579a59 64a464 6cac6c 66a666 589c57 559b54 4a974a 469f45 419940 3d953d 3b913b 388c38 358735 338133 2f7d2f 2b762a 256b26 226122",
    "236751 529755 5e9f5e 64a564 5fa15f 539952 4d974d 479647 46a046 429c43 3e973e 3b933b 388d39 358936 328232 2f7b2f 2b752b 276b27 236027",
    "236751 509654 5d9f5e 64a462 5b9e5b 4d974c 499548 449644 47a046 43a044 3f993e 3d953c 3a903a 378c37 328432 2f7c2f 2b762b 276b27 246127",
    "236750 4a944c 599c59 5e9e5d 589c59 479547 459444 419742 47a046 44a245 419c41 3e983e 3c943c 388e39 348634 2f7c2f 2b762b 276b27 235f25",
    "1f6348 49924c 549a54 589c58 539a53 459444 419341 3f983f 48a246 46a347 43a043 3e9b40 3d963d 399039 348635 2f7c2f 2b752b 256a25 236125",
    "1f6348 48884b 4e994e 529a53 4f9b4f 429341 3e933e 3d983e 47a546 47a547 44a144 409e40 3e983e 3a913a 358735 2f7d2f 2b762b 256a25 236125",
    "206348 418943 4b954b 529a53 4d9a4d 3f933f 3c933c 3e9c3e 49a747 47a847 45a345 419f41 3e9a3e 3a933b 378c37 328032 2b762b 276b27 236123",
    "1f6348 418943 4a954a 4e9a4d 4b9b4a 3e943e 3b933b 3d9f3d 49a848 49aa49 45a445 42a042 3e9b3e 3b953c 378c37 318131 2b762b 256a25 236123",
    "1f6348 3c873e 459545 469a47 439a43 3b963b 399739 3da63e 4aac4a 49ab49 46a646 43a243 3f9d3f 3c963c 378c37 328032 2b762b 256a25 235f25",
    "206448 3b873e 439242 449644 409840 399739 379837 3ea93e 4aaf4a 4aad4a 46a746 44a244 409e40 3c963c 378d38 328132 2b762b 276b27 235f25",
    "216348 3a853e 3e903e 3f9541 3e963f 389737 369836 3fab3e 4ab04a 4aae4a 47a746 44a244 409e41 3e963c 388c37 328032 2a762b 256a25 235f26",
    "1f6246 37843a 3d903e 3d953e 3c963d 379737 369936 3eae3e 49b049 49ae49 46a745 42a343 409e40 3d963c 378d38 328032 2b752b 276a27 246029",
    "206447 338239 3a8c3c 3b913c 39943a 359635 359835 3eaf3e 49ae49 49ad49 45a545 42a143 3f9c40 3c953b 368b37 328032 2a752a 256925 235f2b",
    "1f6247 318336 378b39 39903a 399339 359635 359935 3eae3e 49ac49 49ab49 45a446 439f43 3f9a3f 3b933b 368a36 327e31 296d2b 236224 205820",
    "1e6245 317e34 378a38 398e39 389137 349434 359735 3ead3e 48ab49 48a948 45a245 429d42 3e973e 3b913b 368936 317c31 286929 22612a 1f581f",
    "1e6046 2f7c33 348435 358a36 358e35 339234 349635 3dab3d 48a948 48a548 449f45 429c41 3e963d 3a8e3a 358635 307a2f 276829 235e23 205520",
    "1f6044 2c7732 317f32 328632 328932 318e31 329232 3ca63c 46a346 46a046 429a44 40963f 3d913c 398939 348234 2e752e 256529 215b21 1e521e",
    "1e5e44 29702e 2e782e 2f7e2f 2f822f 2f882f 308c2f 399e39 449b44 449843 3f9340 3c8f3c 398a39 368336 327a31 2b702c 266826 225e22 1f551f",
    "1d5b41 286c2c 2a732a 2b762b 2c7b2c 2c822c 2d852c 369336 419341 409040 3c893c 398739 368236 327b32 2f732e 296829 246124 205820 1e4f1e",
    "1b593f 246928 266b26 276c28 277128 287728 2a792a 328531 3c843c 3a823a 377d37 357a35 327632 2e702e 2b692b 266026 225922 1e501e 1c481c",
    "1a533b 205d24 215e22 225e23 226323 236823 246a25 2b722b 357135 347134 306d32 306c30 2c682d 29612a 265d26 215522 1d4f1d 1a471a 184018",
    "184e39 1e5023 1e5223 1f5226 1e5528 1e5a26 1e5923 255f2f 2c5e31 2c6034 2a5f34 285d31 265b2e 25552d 205227 1e4e26 1b491b 184218 163c16",
];

// The pressed button (menu open) in the middle, one colour per row: a dark
// inner shadow along the top, no highlight, brightest towards the bottom
var PRESSED = "21503b 396b35 357434 2f7d2e 247f25 1d7e20 1c7d1e 1b7a1a 187919 167b19 157f15 158314 148615 138b15 108d12 119012 139213 139213 139213 139213 139213 139213 139213 139213 139213 139213 139213 118011 0e6c0e 0c5a0c";

var table = ROWS.map(row => row.split(" ").map(hex => [0, 2, 4].map(i => parseInt(hex.substr(i, 2), 16))));

var pressedCentre = PRESSED.split(" ").map(hex => [0, 2, 4].map(i => parseInt(hex.substr(i, 2), 16)));

// Each column's colour relative to the middle one, averaged over the
// middle rows: the pressed face keeps the edges' shading but not the
// highlights of the top rows
var MIDDLE = COLUMNS.findIndex(([kind]) => kind === "M");
var columnShade = COLUMNS.map((column, i) => [0, 1, 2].map(channel => {
    let sum = 0;
    for (let r = 8; r <= 20; ++r) {
        sum += table[r][i][channel] / table[r][MIDDLE][channel];
    }
    return sum / 13;
}));

// How far the right edge pulls back from the middle at row y, fitted to
// XP's button: a power curve, fuller at the top than at the bottom
// (4.1 px at the top and 4.5 px at the bottom of a 30 px button).
function pullBack(y, h) {
    const d = Math.abs(y - h / 2) / (h / 2);
    return h * (y < h / 2 ? 0.137 * Math.pow(d, 2.34) : 0.15 * Math.pow(d, 1.8));
}

function mix(a, b, t) {
    return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
}

// Colour samples of row y (interpolated between the table's rows)
function rowAt(y, h, pressed) {
    const r = Math.max(0, Math.min(29, (y + 0.5) * 30 / h - 0.5));
    const top = Math.floor(r);
    const bottom = Math.min(29, top + 1);
    if (pressed) {
        const centre = mix(pressedCentre[top], pressedCentre[bottom], r - top);
        return columnShade.map(shade => [0, 1, 2].map(channel => Math.min(255, centre[channel] * shade[channel])));
    }
    return table[top].map((c, i) => mix(c, table[bottom][i], r - top));
}

// Column centres for a button w wide; the middle colour spans the space
// between the left and right samples
function columnCentres(w, scale) {
    const centres = [];
    COLUMNS.forEach(([kind, offset]) => {
        if (kind === "L") {
            centres.push((offset + 0.5) * scale);
        } else if (kind === "R") {
            centres.push(w - (offset - 0.5) * scale);
        }
    });
    return centres;
}

function css(c) {
    return "rgb(" + Math.round(c[0]) + "," + Math.round(c[1]) + "," + Math.round(c[2]) + ")";
}

// Paints the face into a w × h canvas context, one horizontal gradient per
// pixel row; `look` is "normal", "hover" or "pressed" (menu open). `curved` false draws
// a square right end (vertical panels).
function paint(ctx, w, h, look, curved) {
    const scale = h / 30;
    const middle = MIDDLE;
    const centres = columnCentres(w, scale);
    // Positions from left to right, the middle colour filling the gap
    // between the left and the right samples
    const xs = centres.slice(0, middle).concat([centres[middle - 1] + 10 * scale, centres[middle] - 10 * scale], centres.slice(middle));
    ctx.clearRect(0, 0, w, h);
    for (let y = 0; y < h; ++y) {
        const samples = rowAt(y, h, look === "pressed");
        const colours = samples.slice(0, middle).concat([samples[middle], samples[middle]], samples.slice(middle + 1));
        const gradient = ctx.createLinearGradient(0, 0, w, 0);
        colours.forEach((colour, i) => {
            let c = colour;
            if (look === "hover") {
                c = mix(c, [255, 255, 255], 0.12);
            }
            gradient.addColorStop(Math.max(0, Math.min(1, xs[i] / w)), css(c));
        });
        ctx.fillStyle = gradient;
        const edge = curved ? w - pullBack(y + 0.5, h) : w;
        const full = Math.floor(edge);
        ctx.globalAlpha = 1;
        ctx.fillRect(0, y, full, 1);
        // Antialiasing: the pixel the edge cuts through, by its coverage
        if (edge > full) {
            ctx.globalAlpha = edge - full;
            ctx.fillRect(full, y, 1, 1);
        }
    }
    ctx.globalAlpha = 1;
}
