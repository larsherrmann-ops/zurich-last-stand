import Phaser from 'phaser';

export class BootScene extends Phaser.Scene {
  constructor() { super('boot'); }

  create(): void {
    this.createPlayerTexture();
    this.createZombieTexture();
    this.createWeaponTextures();
    this.scene.start('game');
  }

  private createPlayerTexture(): void {
    const g = this.make.graphics({ x: 0, y: 0 });
    g.fillStyle(0x0b0d0d, 0.42).fillEllipse(32, 78, 44, 11);
    g.fillStyle(0x3f2c23).fillRoundedRect(17, 57, 12, 20, 4).fillRoundedRect(35, 57, 12, 20, 4);
    g.fillStyle(0x17211e).fillRoundedRect(10, 28, 17, 29, 5);
    g.lineStyle(2, 0x0c1212, 0.9).strokeRoundedRect(10, 28, 17, 29, 5);
    g.fillStyle(0x4b6a55).fillRoundedRect(18, 27, 29, 35, 7);
    g.lineStyle(2, 0x18251e, 1).strokeRoundedRect(18, 27, 29, 35, 7);
    g.fillStyle(0x344a3b).fillRect(29, 30, 3, 30);
    g.fillStyle(0xd4a17e).fillRoundedRect(9, 33, 10, 23, 4).fillRoundedRect(45, 33, 10, 23, 4);
    g.fillStyle(0x1a1d1d).fillRoundedRect(48, 35, 18, 5, 2).fillRect(63, 34, 5, 7);
    g.fillStyle(0xd6a17f).fillCircle(33, 19, 14);
    g.fillStyle(0x1b1717).fillEllipse(32, 10, 26, 14).fillTriangle(20, 13, 31, 1, 37, 12).fillTriangle(34, 7, 48, 14, 45, 19);
    g.fillStyle(0x2a1b18).fillRect(23, 20, 18, 3);
    g.fillStyle(0xe0b08b).fillCircle(28, 19, 1.5).fillCircle(38, 19, 1.5);
    g.fillStyle(0xb17748).fillRoundedRect(12, 41, 10, 15, 2);
    g.generateTexture('player', 72, 88).clear();
  }

  private createZombieTexture(): void {
    const g = this.make.graphics({ x: 0, y: 0 });
    g.fillStyle(0x0b0d0d, 0.45).fillEllipse(32, 65, 44, 12);
    g.fillStyle(0x373a36).fillRoundedRect(16, 29, 32, 32, 8);
    g.lineStyle(2, 0x141817, 1).strokeRoundedRect(16, 29, 32, 32, 8);
    g.fillStyle(0x8e8c78).fillCircle(32, 20, 17);
    g.fillStyle(0x3d4037).fillTriangle(17, 14, 25, 2, 29, 14).fillTriangle(38, 8, 51, 14, 43, 21);
    g.fillStyle(0xa9a38a).fillRect(17, 33, 8, 24).fillRect(39, 33, 8, 24);
    g.fillStyle(0x241d1c).fillCircle(26, 19, 3).fillCircle(38, 19, 3);
    g.fillStyle(0xc3443e).fillCircle(26, 19, 1.5).fillCircle(38, 19, 1.5);
    g.fillStyle(0x20191a).fillRoundedRect(25, 26, 15, 5, 2);
    g.fillStyle(0xe0d0ae).fillRect(28, 27, 2, 4).fillRect(35, 27, 2, 4);
    g.fillStyle(0x2e322e).fillRoundedRect(18, 58, 11, 12, 3).fillRoundedRect(35, 58, 11, 12, 3);
    g.generateTexture('zombie', 64, 76).clear();
  }

  private createWeaponTextures(): void {
    const g = this.make.graphics({ x: 0, y: 0 });
    g.fillStyle(0xffd166).fillCircle(4, 4, 4);
    g.generateTexture('bullet', 8, 8).clear();

    g.fillStyle(0x17231f).fillRoundedRect(2, 5, 42, 30, 5);
    g.lineStyle(2, 0x81907e, 0.75).strokeRoundedRect(2, 5, 42, 30, 5);
    g.fillStyle(0x6b7d62).fillRect(8, 10, 30, 4);
    g.fillStyle(0xb7c39f).fillRect(10, 18, 5, 10);
    g.fillStyle(0xd9a342).fillCircle(22, 22, 4).fillCircle(32, 22, 4);
    g.generateTexture('loot', 46, 40).clear();

    g.fillStyle(0xc33f38).fillRoundedRect(2, 2, 50, 36, 5);
    g.lineStyle(2, 0x7d241f, 1).strokeRoundedRect(2, 2, 50, 36, 5);
    g.fillStyle(0xf1dfce).fillRect(22, 8, 10, 24).fillRect(15, 15, 24, 10);
    g.generateTexture('medkit', 54, 40).clear();

    g.fillStyle(0x6d462c).fillRoundedRect(5, 13, 52, 13, 5);
    g.fillStyle(0xa97b4e).fillRect(11, 14, 37, 4);
    g.fillStyle(0x24282a).fillCircle(8, 19, 7).fillCircle(56, 19, 7);
    g.generateTexture('bat', 64, 40).clear();

    g.fillStyle(0x775137).fillRect(1, 7, 116, 26);
    g.lineStyle(2, 0xb4885b, 1).strokeRect(1, 7, 116, 26);
    g.lineStyle(3, 0x2a2520, 1).lineBetween(17, 8, 17, 32).lineBetween(40, 8, 40, 32).lineBetween(63, 8, 63, 32).lineBetween(86, 8, 86, 32);
    g.generateTexture('barricade', 118, 40).clear();
  }
}
