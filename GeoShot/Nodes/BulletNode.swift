//
//  BulletNode.swift
//  GeoShot
//

import SpriteKit

class BulletNode: SKShapeNode {
    let bulletSpeed: CGFloat = 400
    var damage: Int = 1
    var isPiercing: Bool = false
    var hitEnemyIdentifiers: Set<ObjectIdentifier> = []
    let startPosition: CGPoint
    
    init(position: CGPoint, direction: CGVector, damage: Int = 1, isPiercing: Bool = false) {
        self.damage = damage
        self.isPiercing = isPiercing
        self.startPosition = position
        super.init()

        let circlePath = UIBezierPath(arcCenter: .zero, radius: 3, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        self.path = circlePath.cgPath
        self.fillColor = .yellow
        self.strokeColor = .clear
        self.position = position
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
    
    func isOutside(bounds: CGRect, margin: CGFloat = 50) -> Bool {
        position.x < bounds.minX - margin
            || position.x > bounds.maxX + margin
            || position.y < bounds.minY - margin
            || position.y > bounds.maxY + margin
    }
}
