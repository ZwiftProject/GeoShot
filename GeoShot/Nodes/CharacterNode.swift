//
//  CharacterNode.swift
//  GeoShot
//

import SpriteKit

/// Base class for all characters (player and enemies).
class CharacterNode: SKShapeNode {
    private(set) var hp: Int
    let maxHp: Int
    let moveSpeed: CGFloat

    var isAlive: Bool { hp > 0 }

    init(maxHp: Int = 1, moveSpeed: CGFloat = 0, initialHp: Int? = nil) {
        self.maxHp = maxHp
        self.hp = initialHp ?? maxHp
        self.moveSpeed = moveSpeed
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    /// Apply damage to this character. Calls `die()` when hp reaches 0.
    func takeDamage(_ amount: Int = 1) {
        guard hp > 0 else { return }
        hp = max(0, hp - amount)
        if hp == 0 { die() }
    }

    func heal(_ amount: Int = 1) {
        hp = min(maxHp, hp + amount)
    }

    func setHP(_ value: Int) {
        hp = min(max(value, 0), maxHp)
    }

    /// Default death behaviour: remove from parent. Subclasses may override and call `super.die()`.
    func die() {
        removeFromParent()
    }

    /// Default movement hook. Subclasses override this to implement specific movement.
    func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard hp > 0, deltaTime > 0 else { return }

        // Common chase movement: compute normalized direction and apply velocity
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
}

/// Enemy base class that optionally holds a reference to the shared GameState.
class EnemyNode: CharacterNode {
    weak var gameState: GameState?

    init(gameState: GameState? = nil, maxHp: Int = 1, moveSpeed: CGFloat = 0) {
        self.gameState = gameState
        super.init(maxHp: maxHp, moveSpeed: moveSpeed)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
