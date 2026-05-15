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

class PlayerNode: SKShapeNode {
    
    let moveSpeed: CGFloat = 200           // Velocidade de movimento: 200 pixels/segundo
    var gameState: GameState               // Referência ao estado do jogo (vida, pontuação)
    
    // AUTO-AIM: Direção para disparar, calculada pela cena a partir do inimigo mais próximo
    var fireDirection: CGVector = CGVector(dx: 1, dy: 0)
    
    init (gameState: GameState) {
        self.gameState = gameState
        super.init()
        setupShape()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupShape() {
        // Desenha um losango assimétrico (seta) em cyan com borda branca
        // Vértices: topo (0, 20), ponta direita ampliada (30, 0), fundo (0, -20), esquerda curta (-12, 0)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 13))         // topo
        path.addLine(to: CGPoint(x: 30, y: 0))      // ponta direita (mais longa, dá aspecto de seta)
        path.addLine(to: CGPoint(x: 0, y: -13))     // fundo
        path.addLine(to: CGPoint(x: -12, y: 0))     // esquerda (um pouco mais curta)
        path.closeSubpath()
        
        self.path = path
        self.fillColor = .cyan                      // Cor de preenchimento: cyan
        self.strokeColor = .white                   // Cor da borda: branca
        self.lineWidth = 1.5                        // Espessura da borda
        self.name = "player"                        // Identificador para debugging
    }
    
    /// Move o jogador na direção do joystick
    /// - Parameters:
    ///   - direction: CGVector com componentes dx, dy normalizados (entre -1 e 1)
    ///   - deltaTime: Tempo decorrido desde o último frame (em segundos)
    func move(direction: CGVector, deltaTime: TimeInterval) {
        guard gameState.isAlive else { return }     // Só move se o jogador está vivo
        
        // Calcula deslocamento: velocidade * direção * tempo
        let dx = direction.dx * moveSpeed * CGFloat(deltaTime)
        let dy = direction.dy * moveSpeed * CGFloat(deltaTime)
        
        // Atualiza posição
        position = CGPoint(x: position.x + dx, y: position.y + dy)
    }
}
