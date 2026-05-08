//
//  PlayerNode.swift
//  GeoShot
//

import SpriteKit

class PlayerNode: SKShapeNode {
    
    let moveSpeed: CGFloat = 200
    var gameState: GameState
    
    init (gameState: GameState) {
        self.gameState = gameState
        super.init()
        setupShape()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupShape() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 20))
        path.addLine(to: CGPoint(x: 15, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -20))
        path.addLine(to: CGPoint(x: -15, y: 0))
        path.closeSubpath()
        self.path = path
        self.fillColor = .cyan
        self.strokeColor = .white
        self.lineWidth = 1.5
        self.name = "player"
    }
    
    func move(direction: CGVector, deltaTime: TimeInterval) {
        guard gameState.isAlive else { return }
        let dx = direction.dx * moveSpeed * CGFloat(deltaTime)
        let dy = direction.dy * moveSpeed * CGFloat(deltaTime)
        position = CGPoint(x: position.x + dx, y: position.y + dy)
    }
}
