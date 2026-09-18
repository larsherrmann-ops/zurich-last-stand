import Phaser from 'phaser';

export class BootScene extends Phaser.Scene {
  constructor() { super('boot'); }

  create(): void {
    const g = this.make.graphics({ x: 0, y: 0 });
    g.fillStyle(0x4ea35d).fillCircle(16, 16, 16).lineStyle(3, 0xdce8d9).strokeCircle(16, 16, 15);
    g.generateTexture('player', 32, 32).clear();
    g.fillStyle(0x7eaa63).fillCircle(15, 15, 15).fillStyle(0x38532f).fillCircle(10, 11, 3).fillCircle(20, 11, 3);
    g.generateTexture('zombie', 30, 30).clear();
    g.fillStyle(0xffd166).fillCircle(4, 4, 4).generateTexture('bullet', 8, 8).clear();
    g.fillStyle(0xd6b15f).fillRoundedRect(0, 0, 34, 26, 4).generateTexture('loot', 34, 26).clear();
    g.fillStyle(0x7c5638).fillRect(0, 0, 70, 18).lineStyle(2, 0xb98455).strokeRect(0, 0, 70, 18);
    g.generateTexture('barricade', 70, 18).destroy();
    this.scene.start('game');
  }
}
