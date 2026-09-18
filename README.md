# Zurich: Last Stand

Ein 2D-Top-Down-Zombie-Survival-Game in Zürich. Der Spieler plündert Orte, bekämpft Zombies, baut Barrikaden und überlebt immer gefährlichere Nächte.

## Schnellstart unter Windows

Voraussetzungen: Node.js 20 oder neuer und npm.

```powershell
cd C:\Users\lars_\zurich-last-stand
npm install
npm run dev
```

Öffne danach die von Vite angezeigte lokale Adresse, normalerweise `http://localhost:5173`.

## Steuerung

- `WASD` oder Pfeiltasten: laufen
- Maus: zielen
- Linksklick gedrückt halten: schiessen
- `E`: Barrikade bauen (kostet 2 Material)
- `R`: nach Game Over neu starten

## Aktueller Stand (V0.1)

- Spielbare grosse Zürich-Karte mit HB, Bahnhofstrasse, Langstrasse, Bellevue, ETH und Zürichsee
- Bewegung, Zielen und Schiessen
- Zombies verfolgen den Spieler und verursachen Schaden
- Loot gibt Munition, Heilung und Baumaterial
- Barrikaden können gebaut und von Zombies zerstört werden
- Tag-/Nacht-Zyklus; nachts sind Zombies schneller und es erscheint eine Horde
- HUD, Kill-Zähler, Game Over und Neustart
- Keine externen Assets nötig: alle Platzhaltergrafiken werden im Code erzeugt

## Projektstruktur

```text
zurich-last-stand/
├── index.html
├── package.json
├── tsconfig.json
├── README.md
├── CODEX.md
├── docs/
│   ├── GAME_DESIGN.md
│   └── ROADMAP.md
└── src/
    ├── main.ts
    ├── config.ts
    └── scenes/
        ├── BootScene.ts
        └── GameScene.ts
```

## Qualitätskontrolle

Nach jeder Änderung mindestens ausführen:

```powershell
npm run build
```

Wenn Gameplay oder Darstellung verändert wurden, zusätzlich `npm run dev` starten und im Browser testen.
