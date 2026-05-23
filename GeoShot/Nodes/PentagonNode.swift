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

        // Rotate slowly
        self.zRotation += CGFloat(deltaTime) * 0.4

        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > 0 else { return }

        let directionX = dx / distance
        let directionY = dy / distance

        if let body = self.physicsBody {
            body.velocity = CGVector(dx: directionX * moveSpeed, dy: directionY * moveSpeed)
        }
    }

    private var timeSinceLastShot: TimeInterval = 0
    private var currentAttackAngle: CGFloat = 0
    private let fireInterval: TimeInterval = 0.6

    override func updateAttack(targetPosition: CGPoint, deltaTime: TimeInterval) -> [EnemyBulletNode] {
        guard hp > 0 else { return [] }
        timeSinceLastShot += deltaTime
        if timeSinceLastShot >= fireInterval {
            timeSinceLastShot = 0
            
            currentAttackAngle += 0.2
            if currentAttackAngle > CGFloat.pi * 2 {
                currentAttackAngle -= CGFloat.pi * 2
            }
            
            var bullets: [EnemyBulletNode] = []
            let color = SKColor(red: 1, green: 0.55, blue: 0.1, alpha: 1)
            let bulletCount = 5
            let angleStep = CGFloat.pi * 2 / CGFloat(bulletCount)
            
            for i in 0..<bulletCount {
                let angle = currentAttackAngle + CGFloat(i) * angleStep
                let dir = CGVector(dx: cos(angle), dy: sin(angle))
                let bullet = EnemyBulletNode(
                    position: self.position,
                    direction: dir,
                    color: color,
                    radius: 4.5,
                    speed: 220,
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
        gameState?.addScore(100)
    }
}
