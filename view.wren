import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "math" for M
import "./action" for MoveAction, DanceAction, RestAction
import "./events" for GameOverEvent
import "./model" for GameModel
import "./dir" for Dir
import "./keys" for Key

var Keys = [
  "left",
  "right",
  "up",
  "down"
].map {|key| Key.new(key, true, MoveAction.new(key)) }.toList
Keys.add(Key.new("space", true, RestAction.new()))
Keys.add(Key.new("d", true, DanceAction.new()))


var Angles = {
  "left": 90,
  "right": -90,
  "up": 180,
  "down": 0
}

class Animation {
  done=(v) { _done = v }
  done { _done || false }
  t { _t || 0 }
  update() { _t = t + 1 }
  draw() {}
}


class GameView {
  construct init(gameModel) {
    _model = gameModel
    _events = []
    _animations = []
    _ready = true
    updateState()

  }

  update() {
    Keys.each { |key| key.update() }
    if (_ready) {
      for (key in Keys) {
        if (key.firing) {
          System.print("action %(key.action.type)")
          _model.player.action = key.action
          break
        }
      }
      var result = _model.process()
      _ready = _ready && !result.progress && result.events.count == 0
      _animations = processEvents(result.events)
    } else {
      _animations.each {|animation| animation.update() }

      _ready = _animations.count == 0
      if (_ready) {
        updateState()
        if (_gameOver) {
        }
      }
    }

  }

  draw() {
    Canvas.cls()
    var map = _currentMap
    if (_gameOver) {
      // TODO UI Stacking system
      Canvas.print("Game Over", 0, map.height * 8, Color.white)
    } else {
      Canvas.print("Player: %(_model.entities[0].energy)", 0, map.height * 8, Color.white)
      Canvas.print("Blob: %(_model.entities[1].energy)", 0, map.height * 8 + 8, Color.white)
    }
    var player = _model.player


    var offX = (Canvas.width / 2) - (player.x * 8)
    var offY = (Canvas.height / 2) - (player.y * 8)

    var border = 7
    var minX = M.max(player.x - border, 0)
    var maxX = M.min(player.x + border, map.width)
    var minY = M.max(player.y - border, 0)
    var maxY = M.min(player.y + border, map.width)


    for (y in minY...maxY) {
      for (x in minX...maxX) {
        var tile = map.get(x, y)
        if (!tile["dark"]) {
          if (tile.type == 0) {
            Canvas.print(".", offX + x * 8, offY + y * 8, Color.darkgray)
          } else if (tile.type == 1) {
            Canvas.rectfill(offX + x * 8, offY + y * 8, 7, 8, Color.darkgray)
          } else if (tile.type == 2) {
            Canvas.print("*", offX + x * 8, offY + y * 8, Color.blue)
          }
        }
      }
    }

    _model.entities.each {|entity|
      if (!entity.visible) {
        return
      }
      if (entity.type == "player") {
        Canvas.rectfill(offX + 8 * entity.x, offY + 8*entity.y, 8, 8, Color.black)
        Canvas.print("@", offX + 8 * entity.x, offY + 8 * entity.y, Color.white)
      } else if (entity.type == "blob") {
        Canvas.print("s", offX + 8 * entity.x, offY + 8 * entity.y, Color.green)
      }
    }

    // Render one animation at a time
    if (_animations.count > 0) {
      var a = _animations[0]
      a.draw()
      if (a.done) {
        _animations.removeAt(0)
      }
    }
  }

  // Following the Redux model, you can up
  updateState() {
    _currentMap = _model.map
    _currentEnergy = _model.energy
    _gameOver = _gameOverImminent || false
  }

  // Respond to events generated by the Game Model since the last action was taken
  // You can trigger animations here and pass them back to the view
  processEvents(events) {
    return events.map {|event|
      if (event is GameOverEvent) {
        _gameOverImminent = true
        return null
      }
      return null
    }.where {|animation| animation != null }.toList
  }
}

