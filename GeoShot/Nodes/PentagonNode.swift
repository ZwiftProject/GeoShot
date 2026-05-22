//
//  PentagonNode.swift
//  GeoShot
//
// Boss final do Andar 2 — pentágono, muita vida, persegue lentamente.
//

import SpriteKit

final class PentagonNode: SKShapeNode {

    let moveSpeed: CGFloat = 40
    let maxHp: Int = 30
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
