//
//  GameScene.swift
//  GeoShot
//
// CENA PRINCIPAL DO JOGO
// - Gerir o jogador, inimigos, joystick
// - Implementar auto-aim: apontar para inimigo mais próximo
// - Detetar colisões e controlar lógica do combate
//

import SpriteKit

class GameScene: SKScene {
    var gameState = GameState()
    var player: PlayerNode!
    var squared: SquaredNode!
    var joystick: JoystickNode!
    var enemies: [TriangleNode] = []      // Array com todos os inimigos vivos
    
    var joystickTouch: UITouch?
    var fireTouch: UITouch?
    
    private var lastUpdateTime: TimeInterval = 0
    
    // Visualização de auto-aim: círculo verde ao redor do inimigo alvo
    var targetIndicator: SKShapeNode?
    
    override func didMove(to view: SKView) {
        // Configuração inicial da cena
        backgroundColor = SKColor(white: 0.05, alpha: 1)  // Fundo muito escuro (quase preto)
        setupJoystick()      // Criar joystick virtual (esquerda)
        spawnPlayer()        // Criar a Kite no centro
        spawnSquared()       // Inimigo Squared (persegue o jogador)
        spawnEnemies()       // Criar inimigos para teste do auto-aim
    }
    
    /// Cria 5 inimigos Triangle em posições aleatórias para simular o combate
    func spawnEnemies() {
        for _ in 0..<5 {
            let enemy = TriangleNode(gameState: gameState)
            // Posição aleatória dentro dos limites da sala (com margem de 100px)
            enemy.position = CGPoint(
                x: CGFloat.random(in: 100...(size.width - 100)),
                y: CGFloat.random(in: 100...(size.height - 100))
            )
            addChild(enemy)
            enemies.append(enemy)  // Adiciona ao array de rastreamento
        }
    }
    
    func setupJoystick() {
        joystick = JoystickNode()
        joystick.zPosition = 10                  // Mostrar por cima de outros elementos
        addChild(joystick)
    }
    
    func spawnPlayer() {
        player = PlayerNode(gameState: gameState)
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)  // Centro do ecrã
        addChild(player)
    }

    func spawnSquared() {
        squared = SquaredNode()
        squared.position = CGPoint(x: size.width * 0.25, y: size.height * 0.65)
        addChild(squared)
    }
    
    /// Determina se um ponto está na zona do joystick (esquerda)
    func isInJoystickArea(_ p: CGPoint) -> Bool { p.x < size.width * 0.4 }
    
    /// Determina se um ponto está na zona do botão de fogo (direita)
    func isInFireArea(_ p: CGPoint) -> Bool { p.x > size.width * 0.6 }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Quando o dedo toca o ecrã
        for t in touches {
            let loc = t.location(in: self)
            
            // Se o joystick ainda não foi tocado E o toque é na zona esquerda
            if joystickTouch == nil && isInJoystickArea(loc) {
                joystickTouch = t
                joystick.appear(at: loc)   // Joystick aparece onde o dedo pousou
            }
            // Se o botão de fogo ainda não foi tocado E o toque é na zona direita
            else if fireTouch == nil && isInFireArea(loc) {
                fireTouch = t
                // (Disparo será implementado aqui)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Quando o dedo se move (atualizar joystick)
        guard let jt = joystickTouch, touches.contains(jt) else { return }
        joystick.update(to: jt.location(in: self))  // Atualizar posição do thumb
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Quando o dedo se levanta
        for t in touches {
            // Se foi o joystick que se levantou
            if t == joystickTouch {
                joystickTouch = nil
                joystick.disappear()  // Joystick desaparece
            }
            // Se foi o botão de fogo que se levantou
            if t == fireTouch {
                fireTouch = nil
                // (Parar disparo será implementado aqui)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Se o toque for cancelado (ex: gesture do sistema)
        touchesEnded(touches, with: event)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let player = player, let joystick = joystick else { return }

        // Calcular tempo decorrido desde o último frame
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // 1. MOVIMENTO DO JOGADOR
        // Usa a direção do joystick para mover a Kite
        player.move(direction: joystick.direction, deltaTime: deltaTime)

        // Squared persegue o jogador (inimigo base — lento, mais vida)
        if let squared = squared, squared.parent != nil {
            squared.move(towards: player.position, deltaTime: deltaTime)
        }
        
        // 2. AUTO-AIM: ENCONTRAR O INIMIGO MAIS PRÓXIMO
        let closestEnemy = findClosestEnemy(to: player)
        
        // 3. APONTAR E PREPARAR DISPARO
        if let target = closestEnemy {
            // Calcular diferença de posição entre o alvo e o jogador
            let dx = target.position.x - player.position.x
            let dy = target.position.y - player.position.y
            
            // Calcular ângulo usando atan2 (radianos)
            // atan2(y, x) retorna o ângulo em radianos (-π a π)
            let angle = atan2(dy, dx)
            
            // Converter ângulo em vetor normalizado (cos, sin)
            // Este vetor será usado para disparar balas na próxima semana
            player.fireDirection = CGVector(dx: cos(angle), dy: sin(angle))
            
            // Rodar a Kite para visualmente apontar para o alvo
            player.zRotation = angle
            
            // Atualizar indicador visual (círculo verde ao redor do alvo)
            updateTargetIndicator(at: target.position)
        } else {
            // Sem inimigos visíveis: remover indicador
            if targetIndicator != nil {
                targetIndicator?.removeFromParent()
                targetIndicator = nil
            }
        }
    }
    
    // MARK: - AUTO-AIM HELPER METHODS
    
    /// Encontra o inimigo mais próximo do jogador (para auto-aim)
    /// - Parameter player: O nó do jogador
    /// - Returns: O TriangleNode mais próximo, ou nil se não há inimigos
    func findClosestEnemy(to player: PlayerNode) -> TriangleNode? {
        var closestEnemy: TriangleNode? = nil
        var closestDistance = CGFloat.infinity
        
        // Percorrer todos os inimigos
        for enemy in enemies {
            // Calcular distância euclidiana: sqrt((x2-x1)² + (y2-y1)²)
            let dx = enemy.position.x - player.position.x
            let dy = enemy.position.y - player.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            // Se este inimigo é mais próximo que o anterior, guardá-lo
            if distance < closestDistance {
                closestDistance = distance
                closestEnemy = enemy
            }
        }
        
        return closestEnemy
    }
    
    /// Atualiza o indicador visual do alvo (círculo verde)
    /// Cria uma vez e depois apenas move de posição (mais eficiente)
    /// - Parameter position: Posição do inimigo alvo
    func updateTargetIndicator(at position: CGPoint) {
        if targetIndicator == nil {
            // Primeira vez: criar o círculo
            targetIndicator = SKShapeNode(circleOfRadius: 25)
            targetIndicator?.strokeColor = .green         // Cor: verde
            targetIndicator?.lineWidth = 2                // Espessura da linha
            targetIndicator?.fillColor = .clear           // Sem preenchimento (apenas contorno)
            targetIndicator?.zPosition = 1                // Mostrar por cima dos inimigos
            addChild(targetIndicator!)
        }
        
        // Atualizar posição (muito mais eficiente que remover e recriar)
        targetIndicator?.position = position
    }
}
