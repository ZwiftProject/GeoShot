//
//  PlusNode.swift
//  GeoShot
//
// Miniboss do Andar 1 — forma em cruz (+). Stats moderados, persegue lentamente.
//

import SpriteKit

final class PlusNode: EnemyNode {

    init(gameState: GameState? = nil) {
        super.init(gameState: gameState, maxHp: 12, moveSpeed: 55)
        setupShape()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupShape() {
        let thick: CGFloat = 10
        let span: CGFloat = 26
        let cross = CGMutablePath()
        cross.addRect(CGRect(x: -thick / 2, y: -span / 2, width: thick, height: span))
        cross.addRect(CGRect(x: -span / 2, y: -thick / 2, width: span, height: thick))

        self.path = cross
        self.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.9, alpha: 1)
        self.strokeColor = .white
        self.lineWidth = 1.5
        self.name = "plusMiniboss"

        // Physics body for contact
        self.physicsBody = SKPhysicsBody(circleOfRadius: 26)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 0.6
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.player
        self.physicsBody?.collisionBitMask = PhysicsCategory.wall
    }

    override func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard hp > 0, deltaTime > 0 else { return }

        // Rotate continuously
        self.zRotation += CGFloat(deltaTime) * 1.5

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
    private let fireInterval: TimeInterval = 2.5

    override func updateAttack(targetPosition: CGPoint, deltaTime: TimeInterval) -> [EnemyBulletNode] {
        guard hp > 0 else { return [] }
        timeSinceLastShot += deltaTime
        if timeSinceLastShot >= fireInterval {
            timeSinceLastShot = 0
            
            var bullets: [EnemyBulletNode] = []
            let color = SKColor(red: 0.85, green: 0.2, blue: 0.9, alpha: 1)
            
            for i in 0..<4 {
                let angle = self.zRotation + CGFloat(i) * CGFloat.pi / 2
                let dir = CGVector(dx: cos(angle), dy: sin(angle))
                let bullet = EnemyBulletNode(
                    position: self.position,
                    direction: dir,
                    color: color,
                    radius: 5,
                    speed: 200,
                    damage: 1
                )
                bullets.append(bullet)
            }
            return bullets
        }
        return []
    }

    override func die() {
        super.die()
        gameState?.addScore(50)
    }
}
