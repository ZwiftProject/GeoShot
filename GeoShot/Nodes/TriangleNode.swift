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

class TriangleNode: SKShapeNode {

    let moveSpeed: CGFloat
    var health: Int = 1
    var gameState: GameState

    init(gameState: GameState, moveSpeed: CGFloat = 10) {
        self.gameState = gameState
        self.moveSpeed = moveSpeed
        super.init()
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
        self.name = "enemy"                   // Identificador para debugging
    }
    
    func move(towards targetPosition: CGPoint, deltaTime: TimeInterval) {
        guard health > 0, deltaTime > 0 else { return }

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

    /// Função chamada quando uma bala bate no inimigo
    /// - Parameter amount: Dano a receber (normalmente 1)
    func takeDamage(_ amount: Int) {
        health -= amount
        if health <= 0 {
            die()
        }
    }
    
    /// Morte do inimigo: remove-se da cena e adiciona pontuação
    func die() {
        removeFromParent()              // Remove o node do ecrã
        gameState.score += 10           // Adiciona 10 pontos ao jogador
    }
}
