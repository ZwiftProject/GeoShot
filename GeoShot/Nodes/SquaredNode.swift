//
//  SquaredNode.swift
//  GeoShot
//

import SpriteKit

class SquaredNode: EnemyNode {

    init(gameState: GameState? = nil, moveSpeed: CGFloat = 100, maxHp: Int = 3) {
        super.init(gameState: gameState, maxHp: maxHp, moveSpeed: moveSpeed)
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
        gameState?.addScore(10)
    }
}