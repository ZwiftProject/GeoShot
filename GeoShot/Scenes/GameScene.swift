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
    
    override func didMove(to view: SKView) { // Start
        backgroundColor = SKColor(white: 0.05, alpha: 1)
        spawnPlayer()
    }

    func spawnPlayer() {
        player = PlayerNode(gameState: gameState)
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }
}
