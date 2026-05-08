//
//  JoystickNode.swift
//  GeoShot
//

import SpriteKit

class JoystickNode: SKNode {

    let baseRadius: CGFloat = 60
    let thumbRadius: CGFloat = 25
    let maxDistance: CGFloat = 40
    let deadZone: CGFloat = 10

    private var baseNode: SKShapeNode!
    private var thumbNode: SKShapeNode!

    var direction: CGVector = .zero

    // MARK: - Init
    override init() {
        super.init()
        setupBase()
        setupThumb()
        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupBase() {
        baseNode = SKShapeNode(circleOfRadius: baseRadius)
        baseNode.fillColor = UIColor.white.withAlphaComponent(0.1)
        baseNode.strokeColor = UIColor.white.withAlphaComponent(0.4)
        baseNode.lineWidth = 2
        addChild(baseNode)
    }

    private func setupThumb() {
        thumbNode = SKShapeNode(circleOfRadius: thumbRadius)
        thumbNode.fillColor = UIColor.white.withAlphaComponent(0.5)
        thumbNode.strokeColor = .clear
        addChild(thumbNode)
    }

    func appear(at position: CGPoint) {
        self.position = position
        thumbNode.position = .zero
        direction = .zero
        self.isHidden = false
    }

    func update(to touchPosition: CGPoint) {
        let dx = touchPosition.x - position.x
        let dy = touchPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < deadZone {
            direction = .zero
            thumbNode.position = .zero
        } else {
            direction = CGVector(dx: dx / distance, dy: dy / distance)
            let clampedDist = min(distance, maxDistance)
            thumbNode.position = CGPoint(
                x: direction.dx * clampedDist,
                y: direction.dy * clampedDist
            )
        }
    }

    func disappear() {
        direction = .zero
        self.isHidden = true
    }
}
