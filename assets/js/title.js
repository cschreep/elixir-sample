import Phaser from '../vendor/phaser.min'
import socket from './socket'

class TitleScene extends Phaser.Scene {

  preload() {
    this.load.image('background', 'images/background.png');
  }

  create() {
    var bg = this.add.sprite(0,0,'background');
    bg.setOrigin(0,0);

    this.lobbyChannel = socket.channel(`games:lobby`)

    this.lobbyChannel.on("gameAdded", this.addGame)
    this.lobbyChannel.on("gameRemoved", this.removeGame)

    this.lobbyChannel.join()
      .receive("ok", resp => this.showGames(resp["games"]))
      .receive("error", resp => {
        console.log(`Error joining game: `, resp)
      })
  }

  addGame(gameData) {
    console.log("adding game", gameData)
  }
  removeGame(gameData) {
    console.log("removing game", gameData)
  }

  startGame(event) {
    this.lobbyChannel.push("startGame")
      .receive("ok", resp => {
        let gameId = resp['gameId']
        this.joinGame(gameId)
    }).receive("error", resp => {
      console.log(resp)
    })
  }

  showGames(gameList) {
    var self = this;
    let text = self.add.text(100,100, 'Click to start new game');
    text.setInteractive({ useHandCursor: true });
    text.on('pointerdown', event => self.startGame(event));

    gameList.forEach((gameId) => {
      console.log(gameId);
      let self = this;
      let gameLink = self.add.text(50, 50, `Join game ${gameId}`)
      gameLink.setInteractive({ useHandCursor: true});
      gameLink.on('pointerdown', event => {
        this.joinGame(gameId);
      })
    })
  }

  joinGame(gameId) {
    let gameChannel = socket.channel(`games:${gameId}`)
    gameChannel.join()
        .receive("ok", resp => {
          console.log(`Joined game ${gameId}`)
          this.scene.start('WorldScene', {'gameChannel': gameChannel});
         })
        .receive("error", resp => {
          console.log(`Error joining game: `, resp)
         })
  }
}

export default TitleScene
