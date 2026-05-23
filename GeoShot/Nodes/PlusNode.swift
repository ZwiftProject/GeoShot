//
//  PlusNode.swift
//  GeoShot
//
// Miniboss do Andar 1 — forma em cruz (+). Stats moderados, persegue lentamente.
//

import SpriteKit

final class PlusNode: EnemyNode {

    private var isFrenzy: Bool {
        return hp <= maxHp / 2
    }

    init(gameState: GameState? = nil) {
        super.init(gameState: gameState, maxHp: 20, moveSpeed: 55)
        setupShape()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupShape() {
        let thick: CGFloat = 20
        let span: CGFloat = 52
        let cross = CGMutablePath()
        cross.addRect(CGRect(x: -thick / 2, y: -span / 2, width: thick, height: span))
        cross.addRect(CGRect(x: -span / 2, y: -thick / 2, width: span, height: thick))

        self.path = cross
        self.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.9, alpha: 1)
        self.strokeColor = .white
        self.lineWidth = 1.5
        self.name = "plusMiniboss"

        // Physics body for contact
        self.physicsBody = SKPhysicsBody(circleOfRadius: 52)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 0.6
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.player
        self.physicsBody?.collisionBitMask = PhysicsCategory.wall
    }

    override func takeDamage(_ amount: Int = 1) {
        let wasFrenzy = isFrenzy
        super.takeDamage(amount)
        if isAlive && isFrenzy && !wasFrenzy {
            // Entrar no estado de fúria!
            let flash = SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.fillColor = .white
                    self?.strokeColor = .red
                },
                SKAction.wait(forDuration: 0.15),
                SKAction.run { [weak self] in
                    // Vermelho neon brilhante/pulsante para a Fase de Fúria
                    self?.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 1)
                    self?.strokeColor = .white
                }
            ])
            run(flash)

            // Epic growth and pulse visual effect
            let growShrink = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.2)
            ])
            run(growShrink)
        }
    }

    override func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard hp > 0, deltaTime > 0 else { return }

        // Rotação contínua (mais rápida no estado de fúria)
        let rotationSpeed: CGFloat = isFrenzy ? 3.2 : 1.5
        self.zRotation += CGFloat(deltaTime) * rotationSpeed

        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > 0 else { return }

        let directionX = dx / distance
        let directionY = dy / distance
        
        // Movimentação mais rápida no estado de fúria
        let currentSpeed = isFrenzy ? moveSpeed * 1.45 : moveSpeed

        if let body = self.physicsBody {
            body.velocity = CGVector(dx: directionX * currentSpeed, dy: directionY * currentSpeed)
        }
    }

    private var timeSinceLastShot: TimeInterval = 0

    override func updateAttack(targetPosition: CGPoint, deltaTime: TimeInterval) -> [EnemyBulletNode] {
        guard hp > 0 else { return [] }
        
        // Cooldown menor na fase de fúria
        let fireInterval: TimeInterval = isFrenzy ? 1.4 : 2.5
        
        timeSinceLastShot += deltaTime
        if timeSinceLastShot >= fireInterval {
            timeSinceLastShot = 0
            
            // Micro-animação de escala ao disparar
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.12)
            ])
            run(pulse)
            
            var bullets: [EnemyBulletNode] = []
            let color = isFrenzy 
                ? SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 1) 
                : SKColor(red: 0.85, green: 0.2, blue: 0.9, alpha: 1)
            
            // 8 projéteis em estrela na Fase de Fúria, 4 na Fase Normal
            let bulletCount = isFrenzy ? 8 : 4
            let angleStep = CGFloat.pi * 2 / CGFloat(bulletCount)
            
            for i in 0..<bulletCount {
                let angle = self.zRotation + CGFloat(i) * angleStep
                let dir = CGVector(dx: cos(angle), dy: sin(angle))
                let bullet = EnemyBulletNode(
                    position: self.position,
                    direction: dir,
                    color: color,
                    radius: isFrenzy ? 6 : 5,
                    speed: isFrenzy ? 230 : 200,
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
