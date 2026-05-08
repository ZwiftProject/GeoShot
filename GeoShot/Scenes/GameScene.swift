//
//  GameScene.swift
//  GeoShot
//


import SpriteKit

class GameScene: SKScene {
    var gameState = GameState()
    var player: PlayerNode!
    var joystickDirection: CGVector = .zero
    
    var joystickTouch: UITouch?
    var fireTouch: UITouch?
    
    private var lastUpdateTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.05, alpha: 1)
        spawnPlayer()
    }
    
    func spawnPlayer() {
        player = PlayerNode(gameState: gameState)
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }
    
    func isInJoystickArea(_ p: CGPoint) -> Bool { p.x < size.width * 0.4 }
    func isInFireArea(_ p: CGPoint) -> Bool { p.x > size.width * 0.6 }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let loc = t.location(in: self)
            if joystickTouch == nil && isInJoystickArea(loc) {
                joystickTouch = t
            } else if fireTouch == nil && isInFireArea(loc) {
                fireTouch = t
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let jt = joystickTouch, touches.contains(jt) else { return }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if t == joystickTouch {
                joystickTouch = nil
                joystickDirection = .zero
            }
            if t == fireTouch { fireTouch = nil }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesEnded(touches, with: event)
        }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        player.move(direction: joystickDirection, deltaTime: deltaTime)
    }
}
