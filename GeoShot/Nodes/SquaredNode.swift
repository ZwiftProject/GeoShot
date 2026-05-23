//
//  SquaredNode.swift
//  GeoShot
//

import SpriteKit

class SquaredNode: EnemyNode {
    private let scoreValue: Int

    init(gameState: GameState? = nil, moveSpeed: CGFloat = 100, maxHp: Int = 3, difficulty: Int = 1) {
        let scaledHp = Int(ceil(Double(maxHp) * (1.0 + Double(difficulty) * 0.25)))
        let scaledSpeed = moveSpeed * (1.0 + CGFloat(difficulty) * 0.04)
        self.scoreValue = Int((10.0 * (1.0 + Double(difficulty) * 0.30)).rounded())
        super.init(gameState: gameState, maxHp: scaledHp, moveSpeed: scaledSpeed)
        setupShape()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupShape() {
        let side: CGFloat = 34
        let path = CGMutablePath()
        path.addRect(CGRect(x: -side / 2, y: -side / 2, width: side, height: side))

        self.path = path
        self.fillColor = .red
        self.strokeColor = .white
        self.lineWidth = 1.5
        self.name = "squared"

        // Physics body: rectangle matching the visual
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: side, height: side))
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 0.8
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.player
        self.physicsBody?.collisionBitMask = PhysicsCategory.wall
    }


    private var timeSinceLastShot: TimeInterval = 0
    private let fireInterval: TimeInterval = 2.0

    override func updateAttack(targetPosition: CGPoint, deltaTime: TimeInterval) -> [EnemyBulletNode] {
        guard hp > 0 else { return [] }
        timeSinceLastShot += deltaTime
        if timeSinceLastShot >= fireInterval {
            timeSinceLastShot = 0
            
            let dx = targetPosition.x - position.x
            let dy = targetPosition.y - position.y
            let dist = sqrt(dx * dx + dy * dy)
            guard dist > 0 else { return [] }
            
            let dir = CGVector(dx: dx / dist, dy: dy / dist)
            let bullet = EnemyBulletNode(
                position: self.position,
                direction: dir,
                color: .red,
                radius: 6,
                speed: 180,
                damage: 1
            )
            return [bullet]
        }
        return []
    }

    override func die() {
        super.die()
        gameState?.addScore(scoreValue)
    }
}