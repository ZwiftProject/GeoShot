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
    private let scoreValue: Int

    init(gameState: GameState, moveSpeed: CGFloat = 10, difficulty: Int = 1) {
        let scaledHp = Int(ceil(1.0 * (1.0 + Double(difficulty) * 0.25)))
        let scaledSpeed = moveSpeed * (1.0 + CGFloat(difficulty) * 0.04)
        self.scoreValue = Int((10.0 * (1.0 + Double(difficulty) * 0.30)).rounded())
        super.init(gameState: gameState, maxHp: scaledHp, moveSpeed: scaledSpeed)
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

    private enum TriangleState {
        case chasing
        case preparing(targetPos: CGPoint, elapsed: TimeInterval)
        case dashing(direction: CGVector, elapsed: TimeInterval)
        case cooldown(elapsed: TimeInterval)
    }

    private var triangleState: TriangleState = .chasing

    override func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard hp > 0, deltaTime > 0 else { return }
        
        switch triangleState {
        case .chasing:
            let dx = targetPosition.x - position.x
            let dy = targetPosition.y - position.y
            let dist = sqrt(dx * dx + dy * dy)
            
            if dist <= 160.0 {
                // Inicia preparação da investida (dash)
                triangleState = .preparing(targetPos: targetPosition, elapsed: 0.0)
                physicsBody?.velocity = .zero
                
                // Piscar em aviso simples
                let flashAction = SKAction.sequence([
                    SKAction.run { [weak self] in
                        self?.fillColor = .white
                        self?.strokeColor = .red
                    },
                    SKAction.wait(forDuration: 0.11),
                    SKAction.run { [weak self] in
                        self?.fillColor = .orange
                        self?.strokeColor = .white
                    },
                    SKAction.wait(forDuration: 0.11)
                ])
                run(SKAction.repeat(flashAction, count: 2))
            } else {
                super.move(towards: targetPosition, deltaTime: deltaTime)
            }
            
        case .preparing(let lastTarget, let elapsed):
            let newElapsed = elapsed + deltaTime
            if newElapsed >= 0.45 {
                // Calcula direção final e inicia a investida rápida
                let dx = lastTarget.x - position.x
                let dy = lastTarget.y - position.y
                let dist = sqrt(dx * dx + dy * dy)
                let dir = dist > 0 ? CGVector(dx: dx / dist, dy: dy / dist) : CGVector(dx: 0, dy: 1)
                
                triangleState = .dashing(direction: dir, elapsed: 0.0)
                fillColor = .red
                strokeColor = .white
            } else {
                triangleState = .preparing(targetPos: lastTarget, elapsed: newElapsed)
                physicsBody?.velocity = .zero
            }
            
        case .dashing(let dir, let elapsed):
            let newElapsed = elapsed + deltaTime
            if newElapsed >= 0.25 {
                triangleState = .cooldown(elapsed: 0.0)
                physicsBody?.velocity = .zero
                fillColor = .orange
                strokeColor = .white
            } else {
                triangleState = .dashing(direction: dir, elapsed: newElapsed)
                let speedMultiplier: CGFloat = 3.5
                physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed * speedMultiplier, dy: dir.dy * moveSpeed * speedMultiplier)
            }
            
        case .cooldown(let elapsed):
            let newElapsed = elapsed + deltaTime
            if newElapsed >= 0.6 {
                triangleState = .chasing
            } else {
                triangleState = .cooldown(elapsed: newElapsed)
                physicsBody?.velocity = .zero
            }
        }
    }

    override func die() {
        super.die()
        gameState?.addScore(scoreValue)
    }
}
