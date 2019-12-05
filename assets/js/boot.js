import Phaser from '../vendor/phaser.min'

class BootScene extends Phaser.Scene {
  constructor() {
    super({
      key: 'BootScene',
      active: true
    });
  }

  preload() {
    // map tiles
    this.load.image('tiles', 'map/spritesheet-extruded.png');
    // map in json format
    this.load.tilemapTiledJSON('map', 'map/map.json');
    // our two characters
    this.load.spritesheet('player', 'images/RPG_assets.png', {
      frameWidth: 16,
      frameHeight: 16
    });
    this.load.image('golem', 'images/coppergolem.png');
    this.load.image('ent', 'images/dark-ent.png');
    this.load.image('demon', 'images/demon.png');
    this.load.image('worm', 'images/giant-worm.png');
    this.load.image('wolf', 'images/wolf.png');
    this.load.image('sword', 'images/attack-icon.png');
  }

  create() {
    this.scene.start('WorldScene');
  }
}

export default BootScene
