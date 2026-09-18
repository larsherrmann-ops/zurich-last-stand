# Zurich: Last Stand – Roblox

Ein kooperatives Zombie-Survival-Spiel in einer stilisierten Roblox-Version von Zürich. Spieler sammeln Loot, bauen Barrikaden und überleben nachts stärkere Zombie-Horden.

## Spielbare V1

- Zürich-Testmap mit HB, Bahnhofstrasse, Langstrasse, ETH, Bellevue und Zürichsee
- Multiplayer-Grundlage, Zombies, serverseitiges Schiessen und Loot
- Barrikaden mit `E`, Tag/Nacht und HUD

## Start mit Rojo

Installiere Roblox Studio, VS Code, Rojo 7.5+ und das Rojo-Studio-Plugin.

```powershell
cd C:\Users\lars_\zurich-last-stand
rojo serve
```

Roblox Studio öffnen, eine leere Baseplate erstellen, im Rojo-Plugin mit `localhost:34872` verbinden und **Play** drücken. Alternativ:

```powershell
rojo build -o ZurichLastStand.rbxlx
```

## Steuerung

- `WASD`: bewegen
- Maus: Kamera und Zielen
- Linksklick: schiessen
- `E`: Barrikade bauen

## Struktur

```text
├── default.project.json
├── rokit.toml
├── AGENTS.md / CODEX.md / .codex/
├── docs/
└── src/
    ├── shared/Config.luau
    ├── server/*.luau
    └── client/main.client.luau
```

Codex erkennt die Projektregeln und Agenten beim Öffnen automatisch. Gameplay-Änderungen immer in Roblox Studio testen; Multiplayer unter **Test → Start** mit mindestens zwei Spielern.
