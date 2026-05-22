//
//  TriangleNode.swift
//  GeoShot
//
// INIMIGO TIPO TRIANGLE (Triângulo)
// - Forma geométrica laranja que o jogador dispara
// - Persegue a Kite diretamente
// - Tem 1 ponto de vida (morre com 1 bala)
// - Dá 10 pontos ao morrer
//

import SpriteKit

class TriangleNode: EnemyNode {

    init(gameState: GameState, moveSpeed: CGFloat = 10) {
        super.init(gameState: gameState, maxHp: 1, moveSpeed: moveSpeed)
        setupShape()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupShape() {
        // Desenha um triângulo equilátero (laranja com borda branca)
        // Vértices: topo (0, 16), esquerda (-14, -8), direita (14, -8)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 16))        // topo
        path.addLine(to: CGPoint(x: -14, y: -8))   // esquerda
        path.addLine(to: CGPoint(x: 14, y: -8))    // direita
        path.closeSubpath()

        self.path = path
        self.fillColor = .orange              // Cor de preenchimento: laranja
        self.strokeColor = .white             // Cor da borda: branca
        self.lineWidth = 1.5                  // Espessura da borda
        self.name = "enemy"                 // Identificador para debugging

        // Physics body for contacts (use simple circle for performance)
        self.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 0.6
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.player
        self.physicsBody?.collisionBitMask = PhysicsCategory.wall
    }

    override func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
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

    override func die() {
        super.die()
        gameState?.addScore(10)
    }
}
