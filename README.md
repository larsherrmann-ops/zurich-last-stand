# Zurich: Last Stand – Roblox

Ein kooperatives Zombie-Survival-Spiel in der bereinigten Bronx River City Roblox-Map. Die Stadt enthält Straßen, Gebäude, Innenbereiche und Landschaft; das Spiel ergänzt Zombies, Waffen, Loot, Rucksäcke, Attachments, Handel, Barrikaden und Tag/Nacht.

## Spielbarer Prototyp

- Große editierbare Bronx River City als Ausgangswelt
- Server-seitige Schüsse, Zombies, Loot, Barrikaden und Tag/Nacht
- HUD mit Leben, Munition, Material, Kills und Nachtbanner
- Rucksack-Upgrades, Taschenlampe, Rotpunktvisier und erweiterbares Magazin
- Schrotflinte und Sturmgewehr als auffindbare, speicherbare Waffen
- Sichtbare 3D-Loot-Modelle für Waffen, Munition, Medkits, Rucksäcke, Attachments, Geld und Baumaterial
- Grosse Gebäude als Hochrisiko-Zonen mit Premium-Loot und dichterem Zombie-Aufkommen
- Handel mit NPCs und Multiplayer-Spielerhandel
- Türen der Map erhalten sichere ProximityPrompts zum Öffnen und Schließen
- Garagentore fahren beim Öffnen senkrecht nach oben und schließen exakt in ihre Ausgangsposition
- Leere Eingänge erhalten einen begehbaren Boden, Wände, Licht und einen Ausgang; verriegelte Hochrisiko-Gebäude bleiben nur über zerbrochene Fenster zugänglich
- Zerbrochene Fenster öffnen einen animierten Durchgang zum Hineinlaufen

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

## Hochrisiko-Gebäude

Gebäude mit vielen Bauteilen oder grossen Gebäudenamen werden beim Serverstart als
ZurichHighRisk markiert. Sie erhalten mehrere unsichtbare Loot-Punkte mit einer
gewichteten Premium-Tabelle: Schrotflinte, Sturmgewehr, Attachments, Tactical-Rucksack,
Munition, Medkits und mehr Geld. Gleichzeitig werden dort mehrere Zombie-Punkte erzeugt.
Tagsüber landen die meisten neuen Zombies in diesen Bereichen, nachts fast alle; ihre
Lebenspunkte und ihr Schaden sind leicht erhöht. Die Werte stehen in
Config.Loot.HighRisk und Config.Zombie.
## Zombie-Varianten

Die Zombies sind echte Rigs aus dem Creator Store (alle gratis, im Inventar des
Place-Owners). `ZombieModels.luau` lädt sie per `InsertService:LoadAsset`,
**löscht dabei jedes mitgelieferte Script** und behält nur Rig, Meshes und
Animations-IDs. Die KI läuft vollständig über `ZombieService.luau`.

| Variante | Asset | ID | Gewicht | HP | Schaden |
|---|---|---|---|---|---|
| Walker | Drooling Zombie (@Roblox) | 187789986 | 50 | 100 | 10 |
| Runner | Drooling Zombie Rthro (@Roblox) | 3924238625 | 26 | 85 | 8 |
| Brute | Tank Zombie (@trevle0ck) | 5038317529 | 13 | 260 | 22 |
| Crawler | A Zombie. [Enemy] (@Burger_MeaI) | 2791914892 | 9 | 70 | 7 |
| FrostBoss | Frost Boss Zombie (@safulla202020) | 12128443490 | 2 | 900 | 34 |

FrostBoss spawnt nur nachts und maximal einmal gleichzeitig. Ist ein Asset nicht
ladbar, fällt der Service auf den alten Klotz-Zombie zurück, statt gar keinen
Gegner zu spawnen. Konfiguration: `Config.Zombie.Variants`.
