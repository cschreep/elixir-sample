import Phaser from '../vendor/phaser.min'

import TitleScene from './title'
import WorldScene from './world'


var config = {
  type: Phaser.AUTO,
  parent: 'phaser-game',
  width: 320,
  height: 240,
  zoom: 3,
  pixelArt: true,
  physics: {
    default: 'arcade',
    arcade: {
      gravity: {
        y: 0
      },
      debug: true // set to true to view zones
    }
  },
  scene: [
    TitleScene,
    WorldScene,
  ]
};
var game = new Phaser.Game(config);
game.scene.start('TitleScene')
