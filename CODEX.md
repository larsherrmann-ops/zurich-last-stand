# Arbeitsanweisung für Codex – Roblox

## Ziel

Entwickle **Zurich: Last Stand** als kooperatives Roblox-Zombie-Survival-Spiel: am Zürich HB starten, Loot sammeln, eine Base errichten, drei Nächte überleben und am Bürkliplatz per Boot fliehen.

## Technik und Regeln

- Roblox Studio, Luau und Rojo; keine Phaser-, Browser- oder npm-Logik.
- Server-authoritative Regeln für Schaden, Munition, Loot, Bauen und Fortschritt.
- Der Client besitzt nur Eingabe, Kamera, HUD, Effekte und Sounds.
- Validiere Typ, Distanz, Cooldown und Zustand bei jedem `RemoteEvent`.
- Balancing-Werte gehören in `src/shared/Config.luau`.
- Grössere Systeme in Services und Controller aufteilen.
- Nur lizenzierte oder selbst erstellte Modelle, Bilder und Sounds.
- Keine Free Models mit unbekannten Scripts übernehmen.

## Definition of Done

- `rojo build` ist erfolgreich.
- Client-/Server-Grenzen und Remotes sind sicher.
- Sichtbare Änderungen wurden im Studio getestet.
- Multiplayer-Änderungen wurden wenn möglich mit zwei Spielern getestet.
- README/Roadmap wurde bei geänderter Bedienung oder Umfang aktualisiert.
