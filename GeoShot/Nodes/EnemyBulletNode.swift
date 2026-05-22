//
//  EnemyBulletNode.swift
//  GeoShot
//

import SpriteKit

class EnemyBulletNode: SKShapeNode {
    let damage: Int
    let bulletSpeed: CGFloat
    
    init(position: CGPoint, direction: CGVector, color: SKColor, radius: CGFloat, speed: CGFloat, damage: Int = 1) {
        self.damage = damage
        self.bulletSpeed = speed
        super.init()
        
        let circlePath = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        self.path = circlePath.cgPath
        self.fillColor = color
        self.strokeColor = .clear
        self.position = position
        self.name = "enemyBullet"
        self.zPosition = 1
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemyBullet
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.velocity = CGVector(dx: direction.dx * speed, dy: direction.dy * speed)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func isOutside(bounds: CGRect, margin: CGFloat = 50) -> Bool {
        position.x < bounds.minX - margin
            || position.x > bounds.maxX + margin
            || position.y < bounds.minY - margin
            || position.y > bounds.maxY + margin
    }
}
