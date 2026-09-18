# Zurich: Last Stand – Roblox

Ein kooperatives Zombie-Survival-Spiel in einer stilisierten Roblox-Version von Zürich. Spieler sammeln Loot, bauen Barrikaden und überleben nachts stärkere Zombie-Horden.

## Spielbarer Prototyp

- Zürich-Testmap mit HB, Bahnhofstrasse, Langstrasse, ETH, Bellevue und Zürichsee
- Server-seitige Schüsse, Zombies, Loot, Barrikaden und Tag/Nacht
- HUD mit Leben, Munition, Material, Kills und Nachtbanner
- Multiplayer-Grundlage über Roblox Players und RemoteEvents

## Start mit Rojo

In diesem Checkout liegt das eigentliche Roblox-Projekt im Unterordner `zurich-last-stand`:

```powershell
cd C:\Users\lars_\zurich-last-stand\zurich-last-stand
rojo serve
```

Roblox Studio öffnen, eine leere Baseplate erstellen, das Rojo-Plugin über **Plugins → Rojo** öffnen und mit `localhost:34872` verbinden. Danach **Play** drücken und Fehler unter **View → Output** kontrollieren.

Zum Erzeugen einer testbaren Roblox-Datei:

```powershell
rojo build -o ZurichLastStand.rbxlx
```

Der Build wurde lokal mit Rojo 7.7.0 erfolgreich erzeugt.

## Steuerung

- `WASD`: bewegen
- Maus: Kamera und Zielen
- Linksklick: schiessen
- `E`: Barrikade bauen

## Struktur

```text
├── default.project.json
├── rokit.toml
├── AGENTS.md / CODEX.md
└── src/
    ├── shared/Config.luau
    ├── server/*.luau
    └── client/main.client.luau
```

Gameplay-Änderungen werden in Roblox Studio getestet. Multiplayer bitte unter **Test → Start** mit mindestens zwei Spielern prüfen.
