import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "./action" for MoveAction, DanceAction
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
Keys.add(Key.new("space", true, DanceAction.new()))


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
      Canvas.print("Energy: %(_currentEnergy)", 0, map.height * 8, Color.white)
    }
    for (y in 0...map.height) {
      for (x in 0...map.width) {
        var tile = map.get(x, y)
        if (tile.type == 0) {
          Canvas.print(".", x * 8, y * 8, Color.darkgray)
        } else {
          Canvas.print("*", x * 8, y * 8, Color.blue)
        }
      }
    }

    _model.entities.each {|entity|
      if (entity.type == "player") {
        Canvas.rectfill(8 * entity.x, 8*entity.y, 8, 8, Color.black)
        Canvas.print("@", 8 * entity.x, 8 * entity.y, Color.white)
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

