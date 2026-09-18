import Phaser from 'phaser';
import { DAY, PLAYER, WORLD, WEAPON, ZOMBIE } from '../config';

type Zombie = Phaser.Physics.Arcade.Sprite & { lastHit: number; health: number; flashUntil: number };
type ArcadeObject = Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile;

export class GameScene extends Phaser.Scene {
  private player!: Phaser.Physics.Arcade.Sprite;
  private zombies!: Phaser.Physics.Arcade.Group;
  private bullets!: Phaser.Physics.Arcade.Group;
  private loot!: Phaser.Physics.Arcade.Group;
  private barricades!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private overlay!: Phaser.GameObjects.Rectangle;
  private message!: Phaser.GameObjects.Text;
  private hud!: Phaser.GameObjects.Container;
  private profilePanel!: Phaser.GameObjects.Container;
  private phasePanel!: Phaser.GameObjects.Container;
  private locationPanel!: Phaser.GameObjects.Container;
  private weaponPanel!: Phaser.GameObjects.Container;
  private promptPanel!: Phaser.GameObjects.Container;
  private healthBar!: Phaser.GameObjects.Graphics;
  private healthText!: Phaser.GameObjects.Text;
  private materialText!: Phaser.GameObjects.Text;
  private phaseText!: Phaser.GameObjects.Text;
  private timerText!: Phaser.GameObjects.Text;
  private ammoText!: Phaser.GameObjects.Text;
  private promptText!: Phaser.GameObjects.Text;
  private health: number = PLAYER.maxHealth;
  private magazine = WEAPON.magazineSize;
  private reserveAmmo = WEAPON.reserveAmmo;
  private materials = 6;
  private kills = 0;
  private day = 1;
  private isNight = false;
  private phaseStartedAt = 0;
  private lastShot = 0;
  private reloading = false;
  private ended = false;

  constructor() { super('game'); }

  create(): void {
    this.physics.world.setBounds(0, 0, WORLD.width, WORLD.height);
    this.drawZurich();
    this.player = this.physics.add.sprite(1080, 850, 'player').setCollideWorldBounds(true).setDepth(5);
    this.zombies = this.physics.add.group();
    this.bullets = this.physics.add.group({ maxSize: 60 });
    this.loot = this.physics.add.group();
    this.barricades = this.physics.add.staticGroup();

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys('W,A,S,D,E,R') as Record<string, Phaser.Input.Keyboard.Key>;
    this.input.on('pointerdown', (pointer: Phaser.Input.Pointer) => this.shoot(pointer));
    this.input.keyboard!.on('keydown-R', () => { if (this.ended) this.scene.restart(); else this.reload(); });
    this.input.keyboard!.on('keydown-E', () => this.interact());

    this.physics.add.overlap(this.bullets, this.zombies, this.hitZombie, undefined, this);
    this.physics.add.overlap(this.player, this.loot, this.collectLoot, undefined, this);
    this.physics.add.collider(this.zombies, this.barricades, this.attackBarricade, undefined, this);
    this.physics.add.collider(this.player, this.barricades);

    this.cameras.main.setBounds(0, 0, WORLD.width, WORLD.height).startFollow(this.player, true, 0.08, 0.08).setZoom(0.95);
    this.overlay = this.add.rectangle(0, 0, 10000, 10000, 0x071126, 0).setScrollFactor(0).setDepth(20);
    this.createHud();

    this.phaseStartedAt = this.time.now;
    this.spawnZombie(1450, 820);
    this.spawnZombie(480, 370);
    this.spawnLoot(1270, 775, 'medkit');
    this.spawnLoot(1420, 1040, 'loot');
    this.spawnLoot(850, 930, 'loot');
    this.time.addEvent({ delay: 4200, loop: true, callback: () => this.spawnZombie() });
    this.time.addEvent({ delay: DAY.durationMs, loop: true, callback: () => this.toggleDayNight() });
    this.showMessage('TAG 1  ·  ZÜRICH HB SICHERN', 2400);
    this.layoutHud();
  }

  update(time: number): void {
    if (this.ended) {
      this.player.setVelocity(0);
      return;
    }

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
      if (time < zombie.flashUntil) zombie.setTint(0xffc8b0); else zombie.clearTint();
      if (Phaser.Math.Distance.Between(zombie.x, zombie.y, this.player.x, this.player.y) < 38 && time - zombie.lastHit > ZOMBIE.attackDelay) {
        zombie.lastHit = time;
        this.health -= ZOMBIE.damage;
        this.cameras.main.shake(110, 0.008);
        if (this.health <= 0) this.gameOver();
      }
    });

    const secondsLeft = Math.max(0, Math.ceil((DAY.durationMs - (this.time.now - this.phaseStartedAt)) / 1000));
    const minutes = Math.floor(secondsLeft / 60).toString().padStart(2, '0');
    const seconds = (secondsLeft % 60).toString().padStart(2, '0');
    this.timerText.setText(`${this.isNight ? 'NACHT ENDET' : 'NACHT IN'}  ${minutes}:${seconds}`);
    this.updateHud();
  }

  private shoot(pointer: Phaser.Input.Pointer): void {
    if (this.ended || this.reloading || this.time.now - this.lastShot < PLAYER.fireDelay) return;
    if (this.magazine <= 0) {
      this.reload();
      return;
    }

    this.lastShot = this.time.now;
    this.magazine--;
    const target = this.cameras.main.getWorldPoint(pointer.x, pointer.y);
    const bullet = this.bullets.get(this.player.x, this.player.y, 'bullet') as Phaser.Physics.Arcade.Image | null;
    if (!bullet) return;
    bullet.setActive(true).setVisible(true).setDepth(6);
    const angle = Phaser.Math.Angle.Between(this.player.x, this.player.y, target.x, target.y);
    bullet.setRotation(angle);
    this.physics.velocityFromRotation(angle, WEAPON.bulletSpeed, bullet.body!.velocity);
    this.time.delayedCall(900, () => { if (bullet.active) this.bullets.killAndHide(bullet); });
  }

  private reload(): void {
    if (this.ended || this.reloading || this.magazine >= WEAPON.magazineSize || this.reserveAmmo <= 0) return;
    this.reloading = true;
    this.showMessage('NACHLADEN', 800);
    this.time.delayedCall(WEAPON.reloadMs, () => {
      const needed = WEAPON.magazineSize - this.magazine;
      const loaded = Math.min(needed, this.reserveAmmo);
      this.magazine += loaded;
      this.reserveAmmo -= loaded;
      this.reloading = false;
    });
  }

  private hitZombie(bulletObj: ArcadeObject, zombieObj: ArcadeObject): void {
    const bullet = bulletObj as Phaser.Physics.Arcade.Image;
    const zombie = zombieObj as Zombie;
    this.bullets.killAndHide(bullet);
    zombie.health--;
    zombie.flashUntil = this.time.now + 120;
    const hitText = this.add.text(zombie.x, zombie.y - 34, 'TREFFER', {
      fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '13px', color: '#f2d7a1',
      stroke: '#101516', strokeThickness: 3
    }).setOrigin(0.5).setDepth(12);
    this.tweens.add({ targets: hitText, y: hitText.y - 20, alpha: 0, duration: 450, onComplete: () => hitText.destroy() });
    if (zombie.health > 0) return;
    zombie.destroy();
    this.kills++;
    if (Phaser.Math.Between(1, 3) === 1) this.spawnLoot(zombie.x, zombie.y, 'loot');
  }

  private collectLoot(_player: ArcadeObject, lootObj: ArcadeObject): void {
    const loot = lootObj as Phaser.Physics.Arcade.Sprite;
    const kind = loot.getData('kind') as string;
    loot.destroy();
    if (kind === 'medkit') {
      this.health = Math.min(PLAYER.maxHealth, this.health + 28);
      this.showMessage('MEDKIT  +28 GESUNDHEIT', 1000);
    } else {
      this.reserveAmmo += Phaser.Math.Between(6, 10);
      this.materials += Phaser.Math.Between(1, 2);
      this.showMessage('LOOT GESICHERT  ·  MUNITION + MATERIAL', 1000);
    }
  }

  private interact(): void {
    if (this.ended) return;
    const nearby = this.loot.getChildren().find(child => Phaser.Math.Distance.Between(this.player.x, this.player.y, (child as Phaser.GameObjects.GameObject & { x: number; y: number }).x, (child as Phaser.GameObjects.GameObject & { x: number; y: number }).y) < 78);
    if (nearby) this.collectLoot(this.player, nearby as unknown as ArcadeObject); else this.buildBarricade();
  }

  private buildBarricade(): void {
    if (this.materials < 2) { this.showMessage('2 MATERIAL BENÖTIGT', 1000); return; }
    this.materials -= 2;
    const angle = this.player.rotation;
    const x = this.player.x + Math.cos(angle) * 76;
    const y = this.player.y + Math.sin(angle) * 76;
    const barrier = this.barricades.create(x, y, 'barricade') as Phaser.Physics.Arcade.Image;
    barrier.setRotation(angle + Math.PI / 2).setDepth(4).setData('durability', 100).setData('lastHit', 0);
    this.showMessage('BARRIKADE ERRICHTET', 900);
  }

  private attackBarricade(zombieObj: ArcadeObject, barrierObj: ArcadeObject): void {
    const zombie = zombieObj as Zombie;
    const barrier = barrierObj as Phaser.Physics.Arcade.Image;
    if (this.time.now - (zombie.getData('lastBarricadeHit') || 0) < 1000) return;
    zombie.setData('lastBarricadeHit', this.time.now);
    const durability = (barrier.getData('durability') as number) - 20;
    barrier.setData('durability', durability);
    if (durability <= 0) {
      barrier.destroy();
      this.showMessage('BARRIKADE ZERSTÖRT', 900);
    } else {
      barrier.setTint(0xb16d52);
      this.time.delayedCall(140, () => { if (barrier.active) barrier.clearTint(); });
    }
  }

  private spawnZombie(x?: number, y?: number): void {
    if (this.ended || this.zombies.countActive() > 42) return;
    const side = Phaser.Math.Between(0, 3);
    const positions = [
      [Phaser.Math.Between(20, WORLD.width - 20), 20], [WORLD.width - 20, Phaser.Math.Between(20, WORLD.height - 20)],
      [Phaser.Math.Between(20, WORLD.width - 20), WORLD.height - 20], [20, Phaser.Math.Between(20, WORLD.height - 20)]
    ];
    const chosen = positions[side];
    const zombie = this.zombies.create(x ?? chosen[0], y ?? chosen[1], 'zombie') as Zombie;
    zombie.lastHit = 0;
    zombie.health = 2;
    zombie.flashUntil = 0;
    zombie.setDepth(4);
  }

  private spawnLoot(x: number, y: number, kind: 'loot' | 'medkit'): void {
    const item = this.loot.create(x, y, kind === 'medkit' ? 'medkit' : 'loot') as Phaser.Physics.Arcade.Sprite;
    item.setDepth(3).setData('kind', kind);
    this.tweens.add({ targets: item, y: y - 5, duration: 850, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
  }

  private toggleDayNight(): void {
    this.isNight = !this.isNight;
    if (!this.isNight) this.day++;
    this.phaseStartedAt = this.time.now;
    this.tweens.add({ targets: this.overlay, alpha: this.isNight ? 0.46 : 0, duration: 1800 });
    this.cameras.main.flash(500, this.isNight ? 130 : 245, this.isNight ? 150 : 240, this.isNight ? 120 : 200);
    this.showMessage(this.isNight ? `NACHT ${this.day}  ·  DIE HORDE KOMMT` : `TAG ${this.day}  ·  ZEIT ZUM PLÜNDERN`, 2500);
    if (this.isNight) for (let i = 0; i < 7; i++) this.time.delayedCall(i * 180, () => this.spawnZombie());
  }

  private gameOver(): void {
    this.ended = true;
    this.physics.pause();
    this.tweens.add({ targets: this.overlay, alpha: 0.78, duration: 500 });
    this.message.setText(`ZÜRICH IST GEFALLEN\n${this.kills} ZOMBIES BESIEGT  ·  R DRÜCKEN`).setFontSize(30).setY(this.scale.height / 2).setAlpha(1);
  }

  private showMessage(text: string, duration: number): void {
    this.message.setText(text).setAlpha(1);
    this.tweens.killTweensOf(this.message);
    this.tweens.add({ targets: this.message, alpha: 0, delay: duration, duration: 500 });
  }

  private createHud(): void {
    this.hud = this.add.container(0, 0).setScrollFactor(0).setDepth(30);

    this.profilePanel = this.add.container(16, 16);
    this.profilePanel.add(this.makeHudPanel(354, 164));
    this.profilePanel.add(this.add.image(53, 77, 'player').setScale(0.82));
    this.profilePanel.add(this.add.text(96, 18, 'LARS', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '23px', color: '#f0e9d7', fontStyle: 'bold' }));
    this.healthBar = this.add.graphics();
    this.profilePanel.add(this.healthBar);
    this.healthText = this.add.text(96, 73, '', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '14px', color: '#e9e1cf' });
    this.profilePanel.add(this.healthText);
    this.materialText = this.add.text(96, 95, '', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '12px', color: '#aeb9a7' });
    this.profilePanel.add(this.materialText);
    const slots = [
      ['medkit', 'MED', 0], ['loot', 'MUN', 1], ['bat', 'NAH', 2]
    ] as const;
    slots.forEach(([texture, label, index]) => {
      const x = 124 + index * 70;
      this.profilePanel.add(this.add.rectangle(x, 137, 58, 42, 0x11171a, 0.96).setStrokeStyle(1, 0x68716e, 0.9));
      this.profilePanel.add(this.add.image(x, 137, texture).setScale(texture === 'bat' ? 0.5 : 0.62));
      this.profilePanel.add(this.add.text(x - 24, 155, label, { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '9px', color: '#d9d7c8' }));
    });

    this.phasePanel = this.add.container(0, 16);
    this.phasePanel.add(this.makeHudPanel(250, 92));
    this.phaseText = this.add.text(125, 16, '', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '20px', color: '#f1e8d3', fontStyle: 'bold', align: 'center' }).setOrigin(0.5, 0);
    this.timerText = this.add.text(125, 48, '', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '12px', color: '#b9c4bb', align: 'center' }).setOrigin(0.5, 0);
    this.phasePanel.add([this.phaseText, this.timerText]);

    this.locationPanel = this.add.container(0, 16);
    this.locationPanel.add(this.makeHudPanel(210, 80));
    this.locationPanel.add(this.add.text(18, 13, 'ZÜRICH HB', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '17px', color: '#f1e8d3', fontStyle: 'bold' }));
    this.locationPanel.add(this.add.text(18, 40, 'BAHNHOFPLATZ  ·  47.378° N', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '10px', color: '#aeb9a7' }));

    this.weaponPanel = this.add.container(0, 0);
    this.weaponPanel.add(this.makeHudPanel(240, 142));
    this.weaponPanel.add(this.add.text(20, 15, 'PISTOLE', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '18px', color: '#f1e8d3', fontStyle: 'bold' }));
    const weaponIcon = this.add.graphics();
    weaponIcon.fillStyle(0xbac0ba).fillRoundedRect(22, 55, 70, 12, 3).fillRect(55, 64, 14, 28).fillStyle(0x242a2b).fillRect(31, 61, 21, 5);
    weaponIcon.lineStyle(2, 0x0b1112, 1).strokeRoundedRect(22, 55, 70, 12, 3);
    this.weaponPanel.add(weaponIcon);
    this.ammoText = this.add.text(112, 49, '', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '24px', color: '#f1e8d3', fontStyle: 'bold' });
    this.weaponPanel.add(this.ammoText);
    this.weaponPanel.add(this.add.text(112, 84, 'R  NACHLADEN', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '10px', color: '#aeb9a7' }));

    this.promptPanel = this.add.container(0, 0);
    this.promptPanel.add(this.makeHudPanel(230, 48));
    this.promptText = this.add.text(115, 14, '', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '13px', color: '#f1e8d3', fontStyle: 'bold', align: 'center' }).setOrigin(0.5, 0);
    this.promptPanel.add(this.promptText);

    this.message = this.add.text(this.scale.width / 2, 126, '', {
      fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '18px', color: '#f1e8d3',
      backgroundColor: '#11181add', padding: { x: 16, y: 10 }, stroke: '#080b0c', strokeThickness: 3,
      align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(31);

    this.hud.add([this.profilePanel, this.phasePanel, this.locationPanel, this.weaponPanel, this.promptPanel]);
    this.scale.on('resize', this.layoutHud, this);
  }

  private makeHudPanel(width: number, height: number): Phaser.GameObjects.Graphics {
    return this.add.graphics().fillStyle(0x0d1417, 0.92).fillRect(0, 0, width, height).lineStyle(2, 0x66706c, 0.85).strokeRect(0, 0, width, height);
  }

  private layoutHud(): void {
    const width = this.scale.width;
    const height = this.scale.height;
    this.profilePanel.setPosition(16, 16);
    this.phasePanel.setPosition(Math.max(365, width / 2 - 125), 16);
    this.locationPanel.setPosition(Math.max(16, width - 226), 16);
    this.weaponPanel.setPosition(Math.max(16, width - 256), Math.max(210, height - 164));
    this.promptPanel.setPosition(Math.max(16, width / 2 - 115), Math.max(170, height - 62));
    this.message.setPosition(width / 2, Math.max(120, height * 0.16));
  }

  private updateHud(): void {
    this.healthBar.clear();
    this.healthBar.fillStyle(0x1c2525, 1).fillRect(96, 50, 232, 13);
    this.healthBar.fillStyle(this.health > 35 ? 0xb63f3e : 0xe07b4a, 1).fillRect(96, 50, 232 * Math.max(0, this.health) / PLAYER.maxHealth, 13);
    this.healthBar.lineStyle(1, 0x8a918a, 0.8).strokeRect(96, 50, 232, 13);
    this.healthText.setText(`${Math.max(0, this.health)} / ${PLAYER.maxHealth}  GESUNDHEIT`);
    this.materialText.setText(`MATERIAL  ${this.materials.toString().padStart(2, '0')}     ZOMBIES  ${this.kills.toString().padStart(2, '0')}`);
    this.phaseText.setText(`${this.isNight ? 'NACHT' : 'TAG'}  ${this.day}`);
    this.ammoText.setText(`${this.magazine} / ${this.reserveAmmo}`);
    const nearby = this.loot.getChildren().some(child => Phaser.Math.Distance.Between(this.player.x, this.player.y, (child as Phaser.GameObjects.GameObject & { x: number; y: number }).x, (child as Phaser.GameObjects.GameObject & { x: number; y: number }).y) < 78);
    this.promptText.setText(nearby ? 'E   LOOT AUFNEHMEN' : 'E   BARRIKADE BAUEN');
  }

  private drawZurich(): void {
    const g = this.add.graphics().setDepth(0);
    g.fillStyle(0x1b2224).fillRect(0, 0, WORLD.width, WORLD.height);
    g.lineStyle(1, 0x2a3334, 0.45);
    for (let x = 0; x < WORLD.width; x += 72) g.lineBetween(x, 0, x, WORLD.height);
    for (let y = 0; y < WORLD.height; y += 72) g.lineBetween(0, y, WORLD.width, y);

    g.fillStyle(0x2d3538).fillRect(0, 690, WORLD.width, 245).fillRect(545, 0, 190, WORLD.height);
    g.fillStyle(0x222b2e).fillRect(0, 718, WORLD.width, 188).fillRect(570, 0, 140, WORLD.height);
    g.lineStyle(3, 0x69716d, 0.55);
    for (let x = 30; x < WORLD.width; x += 120) g.lineBetween(x, 812, x + 58, 812);
    for (let y = 30; y < WORLD.height; y += 120) g.lineBetween(640, y, 640, y + 58);

    g.fillStyle(0x3e4646).fillRoundedRect(670, 245, 920, 410, 12);
    g.lineStyle(3, 0x707875, 0.65).strokeRoundedRect(670, 245, 920, 410, 12);
    g.fillStyle(0x222b2e).fillRect(760, 296, 740, 102);
    g.fillStyle(0x122941).fillRect(870, 325, 515, 58);
    g.lineStyle(2, 0x8c9b91, 0.8).strokeRect(870, 325, 515, 58);
    this.add.text(1128, 335, '↔  ZÜRICH HB', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '28px', color: '#e9e2cf', fontStyle: 'bold' }).setOrigin(0.5).setDepth(2);
    g.fillStyle(0x151b1d).fillRect(1000, 430, 300, 178);
    g.lineStyle(2, 0x0a0e0f, 1).strokeRect(1000, 430, 300, 178);
    for (let y = 455; y < 600; y += 27) g.fillStyle(0x7f7669).fillRect(1014, y, 272, 15);
    g.fillStyle(0x171e20).fillRect(1126, 430, 6, 178);
    this.drawLamp(935, 470);
    this.drawLamp(1365, 470);
    this.add.text(706, 610, 'BAHNHOFPLATZ', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '19px', color: '#e6dcc5', fontStyle: 'bold' }).setAlpha(0.72).setDepth(1);

    this.drawTram(115, 560);
    this.drawSign(405, 1015, ['Bahnhofplatz', 'Limmatquai', 'Bahnhof  →']);
    this.drawSign(1715, 530, ['Geleise 1–12', 'Shop', 'WC']);
    this.drawBarricadeProp(1610, 690, -0.08);
    this.drawBarricadeProp(1740, 995, 0.04);
    this.drawBarrel(1825, 995);
    this.drawBarrel(1870, 995);
    this.drawCrates(1510, 1110);

    g.fillStyle(0x174052).fillRect(1870, 1010, 530, 590);
    g.lineStyle(2, 0x2e6675, 0.7);
    for (let y = 1040; y < WORLD.height; y += 36) g.lineBetween(1880, y, WORLD.width, y + 12);
    this.add.text(2060, 1190, 'ZÜRICHSEE', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '26px', color: '#b5c7bd', fontStyle: 'bold' }).setAlpha(0.62).setDepth(1);

    const labels = [
      ['BAHNHOFSTRASSE', 900, 1000], ['LANGSTRASSE', 210, 1120], ['BELLEVUE', 1540, 780], ['ETH / UNI', 260, 260]
    ] as const;
    labels.forEach(([label, x, y]) => this.add.text(x, y, label, { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '17px', color: '#aeb8ae', fontStyle: 'bold' }).setAlpha(0.5).setDepth(1));
    this.add.text(1880, 945, 'EVAKUIERUNG  ·  BÜRKLIPLATZ', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '15px', color: '#c8443e', fontStyle: 'bold' }).setAlpha(0.75).setDepth(1);
  }

  private drawTram(x: number, y: number): void {
    const g = this.add.graphics().setDepth(2);
    g.fillStyle(0x0b1113, 0.5).fillRoundedRect(x - 12, y + 28, 470, 174, 26);
    g.fillStyle(0xd9ddd5).fillRoundedRect(x, y, 450, 166, 20);
    g.lineStyle(3, 0x66716d, 1).strokeRoundedRect(x, y, 450, 166, 20);
    g.fillStyle(0x496f8f).fillRect(x + 8, y + 46, 434, 32);
    g.fillStyle(0x1d2b31).fillRoundedRect(x + 26, y + 18, 90, 26, 6).fillRoundedRect(x + 132, y + 18, 90, 26, 6).fillRoundedRect(x + 238, y + 18, 90, 26, 6).fillRoundedRect(x + 344, y + 18, 75, 26, 6);
    g.fillStyle(0xcfd5cf).fillRect(x + 25, y + 90, 398, 46);
    g.lineStyle(3, 0x2a3d46, 1).lineBetween(x + 25, y + 90, x + 423, y + 90);
    g.fillStyle(0xe3aa42).fillCircle(x + 422, y + 136, 8);
    g.fillStyle(0x151b1d).fillCircle(x + 72, y + 166, 24).fillCircle(x + 374, y + 166, 24);
    this.add.text(x + 278, y + 96, '6  ZÜRICH HB', { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '17px', color: '#1d2c31', fontStyle: 'bold' }).setDepth(3);
  }

  private drawSign(x: number, y: number, labels: readonly string[]): void {
    const g = this.add.graphics().setDepth(2);
    g.fillStyle(0x6d7771).fillRect(x + 38, y - 8, 7, 210);
    labels.forEach((label, index) => {
      const top = y + index * 48;
      g.fillStyle(index === 2 ? 0x243b52 : 0x2a4560).fillRoundedRect(x, top, 180, 38, 3);
      g.lineStyle(1, 0x98a397, 0.75).strokeRoundedRect(x, top, 180, 38, 3);
      this.add.text(x + 14, top + 9, label, { fontFamily: 'Arial Narrow, Arial, sans-serif', fontSize: '12px', color: '#e4e4d7' }).setDepth(3);
    });
  }

  private drawLamp(x: number, y: number): void {
    const g = this.add.graphics().setDepth(2);
    g.fillStyle(0xf0bf64, 0.12).fillCircle(x, y, 64);
    g.fillStyle(0x4a4c44).fillRect(x - 4, y, 8, 42);
    g.fillStyle(0xe6c476).fillCircle(x, y - 4, 15);
    g.lineStyle(2, 0xf5e3aa, 0.9).strokeCircle(x, y - 4, 15);
  }

  private drawBarricadeProp(x: number, y: number, rotation: number): void {
    this.add.image(x, y, 'barricade').setScale(1.35, 1.1).setRotation(rotation).setDepth(2);
  }

  private drawBarrel(x: number, y: number): void {
    const g = this.add.graphics().setDepth(2);
    g.fillStyle(0x343b3b).fillRoundedRect(x, y, 42, 74, 8);
    g.lineStyle(2, 0x8f9790, 0.8).strokeRoundedRect(x, y, 42, 74, 8);
    g.lineStyle(3, 0x161b1c, 0.9).lineBetween(x + 5, y + 21, x + 37, y + 21).lineBetween(x + 5, y + 52, x + 37, y + 52);
  }

  private drawCrates(x: number, y: number): void {
    const g = this.add.graphics().setDepth(2);
    g.fillStyle(0x554b3d).fillRect(x, y, 82, 62).fillRect(x + 65, y - 28, 72, 52);
    g.lineStyle(2, 0xa18158, 0.85).strokeRect(x, y, 82, 62).strokeRect(x + 65, y - 28, 72, 52);
    g.lineStyle(2, 0x302b24, 0.9).lineBetween(x, y, x + 82, y + 62).lineBetween(x + 82, y, x, y + 62);
  }
}


