//
//  PentagonNode.swift
//  GeoShot
//
// Boss final do Andar 2 — pentágono, muita vida, persegue lentamente.
//

import SpriteKit

final class PentagonNode: EnemyNode {

    init(gameState: GameState? = nil) {
        super.init(gameState: gameState, maxHp: 30, moveSpeed: 40)
        setupShape()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupShape() {
        let radius: CGFloat = 22
        let path = CGMutablePath()
        let startAngle = CGFloat.pi / 2 + CGFloat.pi / 5
        for i in 0..<5 {
            let angle = startAngle + CGFloat(i) * 2 * CGFloat.pi / 5
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        self.path = path
        self.fillColor = SKColor(red: 1, green: 0.55, blue: 0.1, alpha: 1)
        self.strokeColor = .white
        self.lineWidth = 1.5
        self.name = "pentagonBoss"

        // Physics body for contact
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius + 6)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 0.7
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.player
        self.physicsBody?.collisionBitMask = PhysicsCategory.wall
    }

    override func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard hp > 0, deltaTime > 0 else { return }

        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > 0 else { return }

        let directionX = dx / distance
        let directionY = dy / distance
        let distanceToMove = moveSpeed * CGFloat(deltaTime)

        position = CGPoint(
            x: position.x + directionX * distanceToMove,
            y: position.y + directionY * distanceToMove
        )
    }

    override func die() {
        super.die()
        gameState?.addScore(100)
    }
}
