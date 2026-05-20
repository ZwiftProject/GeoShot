//
//  SquaredNode.swift
//  GeoShot
//

import SpriteKit

class SquaredNode: SKShapeNode {

    let moveSpeed: CGFloat = 100
    let maxHp: Int = 3
    private(set) var hp: Int

    override init() {
        hp = maxHp
        super.init()
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
    }

    func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
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

    func takeDamage(_ amount: Int = 1) {
        guard hp > 0 else { return }

        hp = max(0, hp - amount)
        if hp == 0 {
            removeFromParent()
        }
    }
}