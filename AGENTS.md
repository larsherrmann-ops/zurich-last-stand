# Zurich: Last Stand – Codex Orchestration

## Automatic project behavior

When Codex opens this repository, the main thread acts as the root orchestrator. It owns the user goal, scope, sequencing, integration, verification and final answer. Project-local agents are registered through `.codex/config.toml`.

Codex must first read:

1. `CODEX.md`
2. `README.md`
3. `docs/GAME_DESIGN.md`
4. `docs/ROADMAP.md`
5. relevant source files

The repository is the source of truth. Do not rely on old chat context when current project files answer the question.

## Agent routing

- Small edits and simple fixes: root orchestrator directly.
- Normal implementation, UI, tests and bounded refactors: `terra_worker`.
- Architecture-sensitive or cross-cutting changes: `sol_specialist`.
- Independent review of meaningful or risky work: `sol_reviewer`.
- Only genuine hard blockers, pathfinding/physics/performance or complex algorithms: `astra_specialist`.

Delegation is optional. Use it only when it improves quality, speed or context isolation. Workers may not delegate further. Avoid multiple agents editing the same files. The root always inspects, integrates and verifies worker results.

## Task packet requirements

Every delegated task must state:

- objective and reason,
- files to read first,
- exact scope and exclusions,
- acceptance criteria,
- required build/runtime evidence,
- stop condition.

## Project rules

- TypeScript strict mode and Phaser 3 remain the foundation.
- Preserve current controls and gameplay unless the task explicitly changes them.
- Put shared gameplay values in `src/config.ts`.
- Split new large systems into focused files instead of growing `GameScene.ts` forever.
- Do not add a dependency unless it solves a demonstrated need.
- Do not refactor unrelated code.
- Do not add API keys, secrets, machine-specific absolute paths or unlicensed assets.
- Keep in-game text German and code identifiers English.

## Verification

Before claiming completion:

1. inspect changed files or the diff,
2. run `npm run build`,
3. perform a browser/runtime check for visible gameplay changes when possible,
4. update relevant documentation if controls, architecture or scope changed,
5. report changed files, verification and material remaining risks.

A successful build alone does not prove that gameplay works. Stop after the requested outcome; do not begin the next roadmap milestone automatically.
