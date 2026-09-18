# Zurich: Last Stand – Roblox Codex Orchestration

Der Hauptthread ist der Root-Orchestrator. Vor Arbeit liest er `CODEX.md`, `README.md`, die Game-Design-/Roadmap-Dokumente, `default.project.json` und betroffene Luau-Dateien.

## Routing

- Klein: Root direkt.
- Normale Roblox-Features, UI und Tests: `terra_worker`.
- Architektur, DataStore und Client-/Server-Integration: `sol_specialist`.
- Riskante Änderungen prüfen: `sol_reviewer`.
- Nur echte harte Roblox-, Pathfinding- oder Performanceprobleme: `astra_specialist`.

Workers delegieren nicht. Mehrere Agents bearbeiten nicht dieselben Dateien. Der Root integriert und verifiziert.

## Pflichtregeln

- Server entscheidet über Schaden, Munition, Loot, Bauen und Speicherstände.
- Jeder Clientwert ist potenziell manipuliert; Remotes strikt validieren.
- Keine unbekannten Free-Model-Scripts.
- Shared Config nach `src/shared`, Client nach `src/client`, Server nach `src/server`.
- Keine Phaser-, DOM-, Node- oder Browserlogik.
- Gameplay-Texte Deutsch, Codebezeichner Englisch.
- Vor Fertigmeldung `rojo build` und einen Studio-Playtest durchführen; Multiplayer mit zwei Spielern prüfen oder als offen nennen.
