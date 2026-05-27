//
//  PlayerNode.swift
//  GeoShot
//
// JOGADOR (Kite - Losango)
// - Controlado pelo joystick virtual
// - Auto-aim: aponta automaticamente para o inimigo mais próximo
// - Dispara para o alvo (será implementado)
// - Tem vida (HP) que se reduz com ataques inimigos
//

import SpriteKit

class PlayerNode: CharacterNode {
    let gameState: GameState
    var fireDirection: CGVector = CGVector(dx: 1, dy: 0)
    var shootingRange: CGFloat = 350.0

    override var moveSpeed: CGFloat {
        get {
            let speedUpgrades = gameState.upgrades.filter { $0 == .speed }.count
            return 200.0 + CGFloat(speedUpgrades) * 40.0
        }
        set {
            super.moveSpeed = newValue
        }
    }

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(maxHp: gameState.maxHp, moveSpeed: 200, initialHp: gameState.hp)
        setupShape()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupShape() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 13))
        path.addLine(to: CGPoint(x: 30, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -13))
        path.addLine(to: CGPoint(x: -12, y: 0))
        path.closeSubpath()

        self.path = path
        self.fillColor = .cyan
        self.strokeColor = .white
        self.lineWidth = 1.5
        self.name = "player"

        self.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 2.5
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = PhysicsCategory.wall
    }

    func move(direction: CGVector, deltaTime: TimeInterval) {
        guard isAlive else { return }
        let dx = direction.dx * moveSpeed * CGFloat(deltaTime)
        let dy = direction.dy * moveSpeed * CGFloat(deltaTime)
        position = CGPoint(x: position.x + dx, y: position.y + dy)
    }
}
