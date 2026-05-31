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

    override func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard hp > 0, deltaTime > 0 else { return }
        
        // 1. Calcular distância até o jogador
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0 else { return }
        
        // 2. Determinar o multiplicador de velocidade e cor com base na proximidade
        let closeThreshold: CGFloat = 200.0
        let maxSpeedMultiplier: CGFloat = 2.5
        
        let currentMultiplier: CGFloat
        if distance < closeThreshold {
            // À medida que a distância diminui de 200 para 0, o ratio vai de 0.0 para 1.0
            let ratio = (closeThreshold - distance) / closeThreshold
            currentMultiplier = 1.0 + (maxSpeedMultiplier - 1.0) * ratio
            
            // Transição visual suave de Laranja (1.0, 0.5, 0.0) para Vermelho (1.0, 0.0, 0.0)
            let greenVal = 0.5 * (1.0 - ratio)
            self.fillColor = SKColor(red: 1.0, green: greenVal, blue: 0.0, alpha: 1.0)
        } else {
            currentMultiplier = 1.0
            self.fillColor = .orange
        }
        
        let activeSpeed = moveSpeed * currentMultiplier
        
        // 3. Definir velocidade direta em direção ao jogador
        let directionX = dx / distance
        let directionY = dy / distance
        
        if let body = self.physicsBody {
            body.velocity = CGVector(dx: directionX * activeSpeed, dy: directionY * activeSpeed)
        }
    }

    override func die() {
        super.die()
        gameState?.addScore(scoreValue)
    }
}
