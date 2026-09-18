# Arbeitsanweisung für Codex

## Projektziel

Entwickle **Zurich: Last Stand** schrittweise zu einem gut spielbaren 2D-Top-Down-Zombie-Survival-Game im Browser. Schauplatz ist ein stilisiertes Zürich nach einer Zombie-Katastrophe. Priorität haben gutes Gameplay, verständlicher Code und kleine, testbare Änderungen.

## Technik

- TypeScript im Strict Mode
- Phaser 3 für Rendering, Input und Arcade Physics
- Vite als Entwicklungsserver und Build-System
- Keine neue grosse Library hinzufügen, bevor geprüft wurde, ob Phaser das Problem bereits löst
- Das Spiel muss ohne Backend lokal funktionieren

## Vor jeder Änderung

1. Lies `README.md`, `docs/GAME_DESIGN.md` und `docs/ROADMAP.md`.
2. Untersuche die betroffenen Dateien, bevor du sie änderst.
3. Erkläre kurz, was du ändern willst.
4. Arbeite nur an der verlangten Aufgabe; keine unnötigen Komplettumbauten.

## Regeln für den Code

- Gameplay-Werte gehören nach Möglichkeit in `src/config.ts`.
- Neue grössere Systeme erhalten eine eigene Datei oder Klasse; `GameScene.ts` langfristig aufteilen.
- Verwende sprechende englische Namen im Code und deutsche Texte im Spiel.
- Verwende keine absoluten Pfade, API-Schlüssel oder persönlichen Daten.
- Externe Assets müssen eine klare Lizenz besitzen und unter `public/assets/` dokumentiert werden.
- Keine Platzhalterfunktion als „fertig“ bezeichnen.
- Bestehende Steuerung und Features dürfen nicht unbemerkt kaputtgehen.

## Definition of Done

Eine Aufgabe ist erst fertig, wenn:

- `npm run build` ohne Fehler durchläuft,
- das neue Verhalten manuell geprüft wurde,
- keine offensichtlichen Fehler in Konsole oder Gameplay auftreten,
- README oder Roadmap aktualisiert wurden, falls sich Bedienung oder Funktionsumfang geändert haben,
- Codex am Ende geänderte Dateien, Testergebnis und offene Punkte nennt.

## Gewünschte Entwicklungsreihenfolge

1. Bestehende V0.1 stabilisieren und `GameScene` in Systeme aufteilen.
2. Echte Tilemap für Zürich HB und Bahnhofstrasse erstellen.
3. Verschiedene Waffen, Nachladen und Inventar ergänzen.
4. Solide Zombie-Kollisionen, Navigation und unterschiedliche Zombie-Typen einbauen.
5. Base Building mit Haltbarkeit, Reparatur und Bau-Menü ausbauen.
6. NPCs, Missionen, Speicherstände und weitere Zürcher Gebiete hinzufügen.

## Auftragsschablone

Wenn der Nutzer nur eine Idee nennt, formuliere zuerst eine kleine umsetzbare Story mit Acceptance Criteria. Implementiere danach den kleinsten vollständigen Teil, teste ihn und schlage höchstens den nächsten sinnvollen Schritt vor.
