export const WORLD = { width: 2400, height: 1600 } as const;
export const PLAYER = { speed: 250, maxHealth: 100, fireDelay: 180 } as const;
export const ZOMBIE = { baseSpeed: 58, damage: 10, attackDelay: 650 } as const;
export const DAY = { durationMs: 45_000, nightMultiplier: 1.65 } as const;
