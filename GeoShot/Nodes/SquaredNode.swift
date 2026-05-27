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

    override func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        super.move(towards: targetPosition, deltaTime: deltaTime)
        // Roda continuamente sobre o próprio eixo
        self.zRotation += CGFloat(deltaTime) * 0.8
    }

    private var timeSinceLastShot: TimeInterval = 0
    private let fireInterval: TimeInterval = 2.0
    private let warningDuration: TimeInterval = 0.3
    private var isWarning = false

    override func updateAttack(targetPosition: CGPoint, deltaTime: TimeInterval) -> [EnemyBulletNode] {
        guard hp > 0 else { return [] }
        timeSinceLastShot += deltaTime
        
        // Pulsação visual simples como aviso pré-disparo
        if timeSinceLastShot >= (fireInterval - warningDuration) && !isWarning {
            isWarning = true
            let pulseAction = SKAction.sequence([
                SKAction.scale(to: 1.12, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15)
            ])
            run(pulseAction)
        }
        
        if timeSinceLastShot >= fireInterval {
            timeSinceLastShot = 0
            isWarning = false
            
            let dx = targetPosition.x - position.x
            let dy = targetPosition.y - position.y
            let dist = sqrt(dx * dx + dy * dy)
            guard dist > 0 else { return [] }
            
            let baseAngle = atan2(dy, dx)
            let spreadAngle: CGFloat = 0.25 // ~14 graus de espalhamento
            var bullets: [EnemyBulletNode] = []
            
            for i in -1...1 {
                let angle = baseAngle + CGFloat(i) * spreadAngle
                let dir = CGVector(dx: cos(angle), dy: sin(angle))
                let bullet = EnemyBulletNode(
                    position: self.position,
                    direction: dir,
                    color: .red,
                    radius: 6,
                    speed: 180,
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
        gameState?.addScore(scoreValue)
    }
}