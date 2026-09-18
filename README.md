# Zurich: Last Stand – Roblox

Ein kooperatives Zombie-Survival-Spiel in der bereinigten Bronx River City Roblox-Map. Die Stadt enthält Straßen, Gebäude, Innenbereiche und Landschaft; das Spiel ergänzt Zombies, Waffen, Loot, Rucksäcke, Attachments, Handel, Barrikaden und Tag/Nacht.

## Spielbarer Prototyp

- Große editierbare Bronx River City als Ausgangswelt
- Server-seitige Schüsse, Zombies, Loot, Barrikaden und Tag/Nacht
- HUD mit Leben, Munition, Material, Kills und Nachtbanner
- Rucksack-Upgrades, Taschenlampe, Rotpunktvisier und erweiterbares Magazin
- Handel mit NPCs und Multiplayer-Spielerhandel
- Türen der Map erhalten sichere ProximityPrompts zum Öffnen und Schließen

## Start mit Rojo und der Stadt-Map

Die mitgelieferte Place-Datei `ZurichLastStand.rbxl` ist die bereinigte Bronx River City. Fremde Scripts aus der Download-Map wurden entfernt; die Spiel-Logik kommt aus `src/`.

1. Roblox Studio schließen, falls noch die alte leere Datei geöffnet ist.
2. `ZurichLastStand.rbxl` aus diesem Ordner öffnen.
3. In PowerShell den Rojo-Server starten:

```powershell
cd C:\Users\lars_\zurich-last-stand\zurich-last-stand
rojo serve
```

4. In Roblox Studio **Plugins → Rojo** öffnen und `localhost:34872` verbinden.
5. **Play** drücken und Fehler unter **View → Output** kontrollieren.

Rojo synchronisiert die Scripts in die geöffnete Stadt-Place. Die `World`-Map bleibt dabei erhalten. Wenn du die Stadt bearbeiten möchtest, stoppe Play, ändere Parts/Gebäude in Studio und speichere die Place-Datei.

Zum Erzeugen einer reinen Script-Testdatei:

```powershell
rojo build -o ZurichLastStand.rbxlx
```

## Steuerung

- `WASD`: bewegen
- Maus: Kamera und Zielen
- Linksklick: schießen
- `R`: nachladen
- `F`: Taschenlampe umschalten, sobald gefunden oder gekauft
- `E`: Barrikade bauen
- `B`: Rucksack und Inventar öffnen
- `T`: Handel öffnen
- `H`: Medkit benutzen

## Struktur

```text
├── ZurichLastStand.rbxl
├── default.project.json
├── rokit.toml
└── src/
    ├── shared/Config.luau
    ├── server/*.luau
    └── client/main.client.luau
```

Gameplay-Änderungen werden in Roblox Studio getestet. Multiplayer bitte unter **Test → Start** mit mindestens zwei Spielern prüfen.