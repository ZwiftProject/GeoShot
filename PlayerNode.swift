//
//  PlayerNode.swift
//  GeoShot
//

import Foundation

class PlayerNode: SKShapeNode {
    
    let speed: CGFloat = 200
    var gameState: GameState
    
    init (gameState: GameState) {
        self.gameState = gameState
        super.init()
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
        let dx = direction.dx * speed * CGFloat(deltaTime)
        let dy = direction.dy * speed * CGFloat(deltaTime)
        position = CGPoint(x: position.x + dx, y: position.y + dy)
    }
}
