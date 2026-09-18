import Phaser from 'phaser';
import { DAY, PLAYER, WORLD, ZOMBIE } from '../config';

type Zombie = Phaser.Physics.Arcade.Sprite & { lastHit: number };
type ArcadeObject = Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile;

export class GameScene extends Phaser.Scene {
  private player!: Phaser.Physics.Arcade.Sprite;
  private zombies!: Phaser.Physics.Arcade.Group;
  private bullets!: Phaser.Physics.Arcade.Group;
  private loot!: Phaser.Physics.Arcade.Group;
  private barricades!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private hud!: Phaser.GameObjects.Text;
  private message!: Phaser.GameObjects.Text;
  private overlay!: Phaser.GameObjects.Rectangle;
  private health: number = PLAYER.maxHealth;
  private ammo = 30;
  private materials = 3;
  private kills = 0;
  private day = 1;
  private isNight = false;
  private lastShot = 0;
  private ended = false;

  constructor() { super('game'); }

  create(): void {
    this.physics.world.setBounds(0, 0, WORLD.width, WORLD.height);
    this.drawZurich();
    this.player = this.physics.add.sprite(760, 760, 'player').setCollideWorldBounds(true).setDepth(5);
    this.zombies = this.physics.add.group();
    this.bullets = this.physics.add.group({ maxSize: 60 });
    this.loot = this.physics.add.group();
    this.barricades = this.physics.add.staticGroup();

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys('W,A,S,D,E,R') as Record<string, Phaser.Input.Keyboard.Key>;
    this.input.on('pointerdown', (pointer: Phaser.Input.Pointer) => this.shoot(pointer));
    this.input.keyboard!.on('keydown-R', () => { if (this.ended) this.scene.restart(); });
    this.input.keyboard!.on('keydown-E', () => this.buildBarricade());

    this.physics.add.overlap(this.bullets, this.zombies, this.hitZombie, undefined, this);
    this.physics.add.overlap(this.player, this.loot, this.collectLoot, undefined, this);
    this.physics.add.collider(this.zombies, this.barricades, this.attackBarricade, undefined, this);
    this.physics.add.collider(this.player, this.barricades);

    this.cameras.main.setBounds(0, 0, WORLD.width, WORLD.height).startFollow(this.player, true, 0.08, 0.08).setZoom(1.05);
    this.overlay = this.add.rectangle(0, 0, 10000, 10000, 0x071126, 0).setScrollFactor(0).setDepth(20);
    this.hud = this.add.text(18, 16, '', { fontSize: '18px', color: '#ffffff', backgroundColor: '#101510dd', padding: { x: 12, y: 9 } }).setScrollFactor(0).setDepth(30);
    this.message = this.add.text(this.scale.width / 2, 70, '', { fontSize: '28px', color: '#ffd166', align: 'center', backgroundColor: '#000000bb', padding: { x: 16, y: 9 } }).setOrigin(0.5).setScrollFactor(0).setDepth(31);
    this.scale.on('resize', ({ width }: Phaser.Structs.Size) => this.message.setX(width / 2));

    for (let i = 0; i < 11; i++) this.spawnZombie();
    for (let i = 0; i < 7; i++) this.spawnLoot();
    this.time.addEvent({ delay: 2600, loop: true, callback: () => this.spawnZombie() });
    this.time.addEvent({ delay: DAY.durationMs, loop: true, callback: () => this.toggleDayNight() });
    this.showMessage('TAG 1 – Zürich HB sichern', 2400);
  }

  update(time: number): void {
    if (this.ended) { this.player.setVelocity(0); return; }
    const left = this.keys.A.isDown || this.cursors.left.isDown;
    const right = this.keys.D.isDown || this.cursors.right.isDown;
    const up = this.keys.W.isDown || this.cursors.up.isDown;
    const down = this.keys.S.isDown || this.cursors.down.isDown;
    const direction = new Phaser.Math.Vector2(Number(right) - Number(left), Number(down) - Number(up)).normalize();
    this.player.setVelocity(direction.x * PLAYER.speed, direction.y * PLAYER.speed);
    const pointerWorld = this.cameras.main.getWorldPoint(this.input.activePointer.x, this.input.activePointer.y);
    this.player.setRotation(Phaser.Math.Angle.Between(this.player.x, this.player.y, pointerWorld.x, pointerWorld.y));
    if (this.input.activePointer.isDown && time - this.lastShot >= PLAYER.fireDelay) this.shoot(this.input.activePointer);

    this.zombies.getChildren().forEach(child => {
      const zombie = child as Zombie;
      if (!zombie.active) return;
      const angle = Phaser.Math.Angle.Between(zombie.x, zombie.y, this.player.x, this.player.y);
      this.physics.velocityFromRotation(angle, ZOMBIE.baseSpeed * (this.isNight ? DAY.nightMultiplier : 1), zombie.body!.velocity);
      zombie.setRotation(angle);
      if (Phaser.Math.Distance.Between(zombie.x, zombie.y, this.player.x, this.player.y) < 31 && time - zombie.lastHit > ZOMBIE.attackDelay) {
        zombie.lastHit = time;
        this.health -= ZOMBIE.damage;
        this.cameras.main.shake(110, 0.008);
        if (this.health <= 0) this.gameOver();
      }
    });
    this.hud.setText(`ZÜRICH: LAST STAND  |  ${this.isNight ? 'NACHT' : 'TAG'} ${this.day}\n❤️ ${Math.max(0, this.health)}   🔸 Munition ${this.ammo}   🪵 Material ${this.materials}   ☠ ${this.kills}\nWASD: Laufen  •  Maus: Zielen/Schiessen  •  E: Barrikade`);
  }

  private shoot(pointer: Phaser.Input.Pointer): void {
    if (this.ended || this.ammo <= 0 || this.time.now - this.lastShot < PLAYER.fireDelay) return;
    this.lastShot = this.time.now;
    this.ammo--;
    const target = this.cameras.main.getWorldPoint(pointer.x, pointer.y);
    const bullet = this.bullets.get(this.player.x, this.player.y, 'bullet') as Phaser.Physics.Arcade.Image | null;
    if (!bullet) return;
    bullet.setActive(true).setVisible(true).setDepth(6);
    const angle = Phaser.Math.Angle.Between(this.player.x, this.player.y, target.x, target.y);
    this.physics.velocityFromRotation(angle, 720, bullet.body!.velocity);
    this.time.delayedCall(900, () => bullet.active && this.bullets.killAndHide(bullet));
  }

  private hitZombie(bulletObj: ArcadeObject, zombieObj: ArcadeObject): void {
    const bullet = bulletObj as Phaser.Physics.Arcade.Image;
    const zombie = zombieObj as Zombie;
    this.bullets.killAndHide(bullet);
    zombie.destroy();
    this.kills++;
    if (Phaser.Math.Between(1, 4) === 1) this.spawnLoot(zombie.x, zombie.y);
  }

  private collectLoot(_player: ArcadeObject, lootObj: ArcadeObject): void {
    (lootObj as Phaser.Physics.Arcade.Sprite).destroy();
    this.ammo += Phaser.Math.Between(5, 11);
    this.materials += Phaser.Math.Between(1, 2);
    this.health = Math.min(PLAYER.maxHealth, this.health + Phaser.Math.Between(4, 12));
  }

  private buildBarricade(): void {
    if (this.ended || this.materials < 2) { this.showMessage('Du brauchst 2 Material', 1000); return; }
    this.materials -= 2;
    const angle = this.player.rotation;
    const x = this.player.x + Math.cos(angle) * 58;
    const y = this.player.y + Math.sin(angle) * 58;
    this.barricades.create(x, y, 'barricade').setRotation(angle + Math.PI / 2).refreshBody();
  }

  private attackBarricade(zombieObj: ArcadeObject, barrierObj: ArcadeObject): void {
    const zombie = zombieObj as Zombie;
    if (this.time.now - zombie.lastHit > 1300) {
      zombie.lastHit = this.time.now;
      this.time.delayedCall(250, () => (barrierObj as Phaser.Physics.Arcade.Image).destroy());
    }
  }

  private spawnZombie(): void {
    if (this.ended || this.zombies.countActive() > 55) return;
    const side = Phaser.Math.Between(0, 3);
    const positions = [
      [Phaser.Math.Between(20, WORLD.width - 20), 20], [WORLD.width - 20, Phaser.Math.Between(20, WORLD.height - 20)],
      [Phaser.Math.Between(20, WORLD.width - 20), WORLD.height - 20], [20, Phaser.Math.Between(20, WORLD.height - 20)]
    ];
    const [x, y] = positions[side];
    const zombie = this.zombies.create(x, y, 'zombie') as Zombie;
    zombie.lastHit = 0;
    zombie.setDepth(4);
  }

  private spawnLoot(x = Phaser.Math.Between(120, WORLD.width - 120), y = Phaser.Math.Between(120, WORLD.height - 120)): void {
    this.loot.create(x, y, 'loot').setDepth(3);
  }

  private toggleDayNight(): void {
    this.isNight = !this.isNight;
    if (!this.isNight) this.day++;
    this.tweens.add({ targets: this.overlay, alpha: this.isNight ? 0.46 : 0, duration: 1800 });
    this.showMessage(this.isNight ? `NACHT ${this.day} – Die Horde kommt` : `TAG ${this.day} – Zeit zum Plündern`, 2500);
    if (this.isNight) for (let i = 0; i < 9; i++) this.time.delayedCall(i * 170, () => this.spawnZombie());
  }

  private gameOver(): void {
    this.ended = true;
    this.physics.pause();
    this.message.setText(`ZÜRICH IST GEFALLEN\n${this.kills} Zombies besiegt · Drücke R`).setFontSize(34).setY(this.scale.height / 2);
  }

  private showMessage(text: string, duration: number): void {
    this.message.setText(text).setAlpha(1);
    this.tweens.killTweensOf(this.message);
    this.tweens.add({ targets: this.message, alpha: 0, delay: duration, duration: 500 });
  }

  private drawZurich(): void {
    const g = this.add.graphics();
    g.fillStyle(0x263126).fillRect(0, 0, WORLD.width, WORLD.height);
    g.fillStyle(0x434943);
    for (let x = 100; x < WORLD.width; x += 310) g.fillRect(x, 0, 74, WORLD.height);
    for (let y = 120; y < WORLD.height; y += 260) g.fillRect(0, y, WORLD.width, 68);
    g.fillStyle(0x1b5271).fillRect(1780, 780, 620, 820);
    g.fillStyle(0x4b5049);
    for (let x = 210; x < 1700; x += 310) for (let y = 225; y < 1450; y += 260) g.fillRoundedRect(x, y, 180, 118, 8);
    const labels = [
      ['ZÜRICH HB', 610, 680], ['BAHNHOFSTRASSE', 1040, 570], ['LANGSTRASSE', 230, 1010],
      ['BELLEVUE', 1510, 920], ['ZÜRICHSEE', 1980, 1090], ['ETH', 1350, 260]
    ] as const;
    labels.forEach(([label, x, y]) => this.add.text(x, y, label, { fontSize: '25px', color: '#d7dccb', fontStyle: 'bold' }).setAlpha(0.68));
  }
}
