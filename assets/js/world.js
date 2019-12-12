import socket from './socket'

import Phaser from '../vendor/phaser.min'

class WorldScene extends Phaser.Scene {
  constructor() {
    super({
      key: 'WorldScene',
      active: false
    });
  }

  init(data) {
    this.gameChannel = data['gameChannel']
  }

  preload() {
    this.load.image('tiles', 'map/spritesheet-extruded.png');
    this.load.tilemapTiledJSON('map', 'map/map.json');
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
    this.createMap();
    this.createAnimations();
    this.createEnemies();
    this.createPlayers();
    this.createCursors();
    this.createSocketHandlers();

    this.gameChannel.push('addPlayer', {
      'playerId': this.player.playerId,
      'x': this.player.x,
      'y': this.player.y
    })
      .receive("ok", resp => {})
      .receive("error", resp => {})

  }

  createSocketHandlers() {

    this.gameChannel.on("newPlayer", resp => {
      this.createOtherPlayer(resp)
    });

    this.gameChannel.on("currentPlayers", resp => {
      const self = this;
      let players = resp;
      Object.keys(players).forEach(function (id) {
          self.createOtherPlayer(players[id]);
      })
    });

    this.gameChannel.on("playerMoved", playerInfo => {
      const self = this;

      this.otherPlayers.getChildren().forEach(player => {
        if (player.playerId == playerInfo.id) {
          this.syncPlayerMovement(player, playerInfo);
        }
      });
    });

    this.gameChannel.on("playerLeft", resp => {
      this.removePlayer(resp["playerId"])
    })

    this.gameChannel.on("syncDown", playerInfo => {
      const self = this;

      this.otherPlayers.getChildren().forEach(player => {
        if (player.playerId == playerInfo.id) {
          this.syncPlayerMovement(player, playerInfo);
          this.syncPlayerLocation(player, playerInfo);
        }
      });
    })

    this.timedEvent = this.time.addEvent({
      delay: 3000,
      callback: this.syncUp,
      callbackScope: this,
      loop: true
    });
  }

  syncUp() {
    this.gameChannel.push("syncUp", {
      'playerId': this.player.playerId,
      'x': this.player.x,
      'y': this.player.y,
      'moveLeft': this.player.moveLeft,
      'moveRight': this.player.moveRight,
      'moveUp': this.player.moveUp,
      'moveDown': this.player.moveDown,
    }).receive("ok", resp => {
    }).receive("error", resp => {
    })
  }

  syncPlayerMovement(player, playerInfo) {
    player.moveLeft = playerInfo.moveLeft;
    player.moveRight = playerInfo.moveRight;
    player.moveUp = playerInfo.moveUp;
    player.moveDown = playerInfo.moveDown;
  }

  syncPlayerLocation(player, playerInfo) {
    player.x = playerInfo.x;
    player.y = playerInfo.y;
  }

  createMap() {
    // create the map
    this.map = this.make.tilemap({
      key: 'map'
    });

    // first parameter is the name of the tilemap in tiled
    var tiles = this.map.addTilesetImage('spritesheet', 'tiles', 16, 16, 1, 2);

    // creating the layers
    this.map.createStaticLayer('Grass', tiles, 0, 0);
    this.map.createStaticLayer('Obstacles', tiles, 0, 0);

    // don't go out of the map
    this.physics.world.bounds.width = this.map.widthInPixels;
    this.physics.world.bounds.height = this.map.heightInPixels;
}

  createAnimations() {
    //  animation with key 'left', we don't need left and right as we will use one and flip the sprite
    this.anims.create({
      key: 'left',
      frames: this.anims.generateFrameNumbers('player', {
        frames: [1, 7, 1, 13]
      }),
      frameRate: 10,
      repeat: -1
    });

    // animation with key 'right'
    this.anims.create({
      key: 'right',
      frames: this.anims.generateFrameNumbers('player', {
        frames: [1, 7, 1, 13]
      }),
      frameRate: 10,
      repeat: -1
    });

    this.anims.create({
      key: 'up',
      frames: this.anims.generateFrameNumbers('player', {
        frames: [2, 8, 2, 14]
      }),
      frameRate: 10,
      repeat: -1
    });

    this.anims.create({
      key: 'down',
      frames: this.anims.generateFrameNumbers('player', {
        frames: [0, 6, 0, 12]
      }),
      frameRate: 10,
      repeat: -1
    });
  }

  updateCamera() {
    // limit camera to map
    this.cameras.main.setBounds(0, 0, this.map.widthInPixels, this.map.heightInPixels);
    this.cameras.main.startFollow(this.player);
    this.cameras.main.roundPixels = true; // avoid tile bleed
  }

  createEnemies() {
    this.spawns = this.physics.add.group({
      classType: Phaser.GameObjects.Sprite
    });
    for (var i = 0; i < 20; i++) {
      const location = this.getValidLocation();
      // parameters are x, y, width, height
      var enemy = this.spawns.create(location.x, location.y, this.getEnemySprite());
      enemy.body.setCollideWorldBounds(true);
      enemy.body.setImmovable();
    }
    this.timedEvent = this.time.addEvent({
      delay: 3000,
      callback: this.moveEnemies,
      callbackScope: this,
      loop: true
    });
  }

  getEnemySprite() {
    var sprites = ['golem', 'ent', 'demon', 'worm', 'wolf'];
    return sprites[Math.floor(Math.random() * sprites.length)];
  }

  getValidLocation() {
    var validLocation = false;
    var x, y;
    while (!validLocation) {
      x = Phaser.Math.RND.between(0, this.physics.world.bounds.width);
      y = Phaser.Math.RND.between(0, this.physics.world.bounds.height);

      var occupied = false;
      if (this.spawns) {
        this.spawns.getChildren().forEach((child) => {
          if (child.getBounds().contains(x, y)) {
            occupied = true;
          }
        });
      }
      if (!occupied) validLocation = true;
    }
    return { x, y };
  }

  createPlayers() {
    // our player sprite created through the physics system
    const location = this.getValidLocation();
    this.player = this.add.sprite(location.x, location.y, 'player', 6);
    this.player.isAttacking = false;
    this.player.name = 'playerSprite'
    this.player.playerId = `player-${Math.floor(Math.random() * 10000)}`

    this.physics.world.enable(this.player);

    // update camera
    this.updateCamera();

    // don't go out of the map
    this.player.body.setCollideWorldBounds(true);

    // add collider
    this.physics.add.overlap(this.player, this.spawns, this.onMeetEnemy, false, this);

    // other players
    this.otherPlayers = this.physics.add.group();
  }

  createOtherPlayer(playerInfo) {
    const otherPlayer = this.add.sprite(playerInfo.x, playerInfo.y, 'player', 9);
    otherPlayer.setTint(Math.random() * 0xffffff);
    otherPlayer.playerId = playerInfo.id;
    this.otherPlayers.add(otherPlayer);
  }

  onMeetEnemy(player, enemy) {
    // TODO some actual gameplay
    if (this.player.isAttacking) {
      const location = this.getValidLocation();
      enemy.x = location.x;
      enemy.y = location.y;
    }
  }

  animatePlayer(player) {

    player.anims.stop()

    if (player.moveLeft) {
      player.flipX = true;
      player.anims.play('left', true);
      player.body.setVelocityX(-80);
    }
    else if (player.moveRight) {
      player.flipX = false;
      player.anims.play('right', true);
      player.body.setVelocityX(80);
    } else {
      player.body.setVelocityX(0);
    }

    if (player.moveUp) {
      player.anims.play('up', true);
      player.body.setVelocityY(-80);
    } else if (player.moveDown) {
      player.anims.play('down', true);
      player.body.setVelocityY(80);
    } else {
      player.body.setVelocityY(0);
    }
  }

  createCursors() {
    this.cursors = this.input.keyboard.createCursorKeys();

    this.cursors.left.on('down', event => {
      this.player.moveLeft = true;
      this.gameChannel.push("movePlayer", {"moveLeft": true});
    });
    this.cursors.left.on('up', event => {
      this.player.moveLeft = false;
      this.gameChannel.push("movePlayer", {"moveLeft": false});
    });

    this.cursors.right.on('down', event => {
      this.player.moveRight = true;
      this.gameChannel.push("movePlayer", {"moveRight": true});
    });
    this.cursors.right.on('up', event => {
      this.player.moveRight = false;
      this.gameChannel.push("movePlayer", {"moveRight": false});
    });

    this.cursors.up.on('down', event => {
      this.player.moveUp = true;
      this.gameChannel.push("movePlayer", {"moveUp": true});
    });
    this.cursors.up.on('up', event => {
      this.player.moveUp = false;
      this.gameChannel.push("movePlayer", {"moveUp": false});
    });

    this.cursors.down.on('down', event => {
      this.player.moveDown = true;
      this.gameChannel.push("movePlayer", {"moveDown": true});
    });
    this.cursors.down.on('up', event => {
      this.player.moveDown = false;
      this.gameChannel.push("movePlayer", {"moveDown": false});
    });

    this.cursors.space.on('up', event => {
      this.player.isAttacking = false;
    })

    this.cursors.space.on('down', event => {
      this.player.isAttacking = true;
    })
  }

  update() {
    this.animatePlayer(this.player);
    this.otherPlayers.getChildren().forEach(player => {
      this.animatePlayer(player);
   });
  }

  moveEnemies () {
    this.spawns.getChildren().forEach((enemy) => {
      const randNumber = Math.floor((Math.random() * 4) + 1);

      switch(randNumber) {
        case 1:
          enemy.body.setVelocityX(50);
          break;
        case 2:
          enemy.body.setVelocityX(-50);
          break;
        case 3:
          enemy.body.setVelocityY(50);
          break;
        case 4:
          enemy.body.setVelocityY(-50);
          break;
        default:
          enemy.body.setVelocityX(50);
      }
      });

    setTimeout(() => {
      this.spawns.setVelocityX(0);
      this.spawns.setVelocityY(0);
    }, 500);
  }

}

export default WorldScene
