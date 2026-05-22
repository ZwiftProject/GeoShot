//
//  BulletNode.swift
//  GeoShot
//

import SpriteKit

class BulletNode: SKShapeNode {
    // Use a different name to avoid conflicting with SKNode.speed
    let bulletSpeed: CGFloat = 400  // pixels por segundo
    var velocity: CGVector = .zero    // direção normalizada
    
    init(position: CGPoint, direction: CGVector) {
        super.init()
        
        // Criar um pequeno círculo
        let circlePath = UIBezierPath(arcCenter: .zero, radius: 3, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        self.path = circlePath.cgPath
        self.fillColor = .yellow
        self.strokeColor = .clear
        self.position = position
        self.velocity = direction
        self.name = "bullet"
        self.zPosition = 0
        self.physicsBody = SKPhysicsBody(circleOfRadius: 3)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.categoryBitMask = PhysicsCategory.bullet
        self.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.wall
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.velocity = CGVector(dx: direction.dx * bulletSpeed, dy: direction.dy * bulletSpeed)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    /// Atualiza a posição da bala baseada na velocidade e tempo decorrido
    func update(deltaTime: TimeInterval) {
        // Bullet movement is handled by physics body velocity. Ensure fallback if physicsBody missing.
        if let body = physicsBody {
            // nothing to do; physics updates position
        } else {
            let dx = velocity.dx * bulletSpeed * CGFloat(deltaTime)
            let dy = velocity.dy * bulletSpeed * CGFloat(deltaTime)
            position = CGPoint(x: position.x + dx, y: position.y + dy)
        }
    }
    
    /// Verifica se a bala saiu dos limites do mundo da sala.
    func isOutside(bounds: CGRect, margin: CGFloat = 50) -> Bool {
        position.x < bounds.minX - margin
            || position.x > bounds.maxX + margin
            || position.y < bounds.minY - margin
            || position.y > bounds.maxY + margin
    }
}
