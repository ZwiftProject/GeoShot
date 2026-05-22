//
//  PlusNode.swift
//  GeoShot
//
// Miniboss do Andar 1 — forma em cruz (+). Stats moderados, persegue lentamente.
//

import SpriteKit

final class PlusNode: SKShapeNode {

    let moveSpeed: CGFloat = 55
    let maxHp: Int = 12
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
