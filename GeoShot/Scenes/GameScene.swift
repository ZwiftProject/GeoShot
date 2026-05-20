//
//  GameScene.swift
//  GeoShot
//
// CENA PRINCIPAL DO JOGO
// - Gerir o jogador, inimigos, joystick
// - Auto-aim: apontar para o inimigo mais próximo (triângulos + quadrado)
// - Detetar colisões e controlar lógica do combate
//

import SpriteKit

class GameScene: SKScene {
    var gameState = GameState()
    var player: PlayerNode!
    var squared: SquaredNode!
    var joystick: JoystickNode!
    var enemies: [TriangleNode] = []
    var bullets: [BulletNode] = []

    var joystickTouch: UITouch?
    var fireTouch: UITouch?

    private var lastUpdateTime: TimeInterval = 0
    private var lastFireTime: TimeInterval = 0
    private let fireRate: TimeInterval = 0.5

    var targetIndicator: SKShapeNode?

    private var isFiring: Bool { fireTouch != nil }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.05, alpha: 1)
        setupJoystick()
        spawnPlayer()
        spawnSquared()
        spawnEnemies()
    }

    func spawnEnemies() {
        for _ in 0..<5 {
            let enemy = TriangleNode(gameState: gameState)
            enemy.position = CGPoint(
                x: CGFloat.random(in: 100...(size.width - 100)),
                y: CGFloat.random(in: 100...(size.height - 100))
            )
            addChild(enemy)
            enemies.append(enemy)
        }
    }

    func setupJoystick() {
        joystick = JoystickNode()
        joystick.zPosition = 10
        addChild(joystick)
    }

    func spawnPlayer() {
        player = PlayerNode(gameState: gameState)
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    func spawnSquared() {
        squared = SquaredNode()
        squared.position = CGPoint(x: size.width * 0.25, y: size.height * 0.65)
        addChild(squared)
    }

    func isInJoystickArea(_ p: CGPoint) -> Bool { p.x < size.width * 0.4 }

    func isInFireArea(_ p: CGPoint) -> Bool { p.x > size.width * 0.6 }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let loc = t.location(in: self)

            if joystickTouch == nil && isInJoystickArea(loc) {
                joystickTouch = t
                joystick.appear(at: loc)
            } else if fireTouch == nil && isInFireArea(loc) {
                fireTouch = t
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let jt = joystickTouch, touches.contains(jt) else { return }
        joystick.update(to: jt.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if t == joystickTouch {
                joystickTouch = nil
                joystick.disappear()
            }
            if t == fireTouch {
                fireTouch = nil
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let player = player, let joystick = joystick else { return }

        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        let movementAngle: CGFloat? = joystick.direction != .zero
            ? atan2(joystick.direction.dy, joystick.direction.dx)
            : nil

        player.move(direction: joystick.direction, deltaTime: deltaTime)

        if let squared = squared, squared.parent != nil {
            squared.move(towards: player.position, deltaTime: deltaTime)
        }

        for enemy in enemies where enemy.parent != nil {
            enemy.move(towards: player.position, deltaTime: deltaTime)
        }

        let closestTarget = findClosestTarget(to: player)

        if let target = closestTarget {
            let dx = target.position.x - player.position.x
            let dy = target.position.y - player.position.y
            let angle = atan2(dy, dx)

            player.fireDirection = CGVector(dx: cos(angle), dy: sin(angle))

            if isFiring {
                player.zRotation = angle
            } else if let movementAngle = movementAngle {
                player.zRotation = movementAngle
            }

            updateTargetIndicator(at: target.position)
        } else {
            if targetIndicator != nil {
                targetIndicator?.removeFromParent()
                targetIndicator = nil
            }

            if let movementAngle = movementAngle {
                player.zRotation = movementAngle
            }
        }

        if isFiring && currentTime - lastFireTime >= fireRate {
            let bullet = BulletNode(position: player.position, direction: player.fireDirection)
            addChild(bullet)
            bullets.append(bullet)
            lastFireTime = currentTime
        }

        for bullet in bullets {
            bullet.update(deltaTime: deltaTime)
        }
        bullets.removeAll { $0.isOffScreen(sceneSize: size) }
        bullets.removeAll { $0.parent == nil }

        checkBulletEnemyCollisions()
    }

    private func checkBulletEnemyCollisions() {
        var bulletIndicesToRemove = Set<Int>()
        var enemyIndicesToRemove = Set<Int>()

        for (bulletIndex, bullet) in bullets.enumerated() {
            guard !bulletIndicesToRemove.contains(bulletIndex) else { continue }

            if let sq = squared, sq.parent != nil, sq.hp > 0 {
                let dSq = hypot(
                    bullet.position.x - sq.position.x,
                    bullet.position.y - sq.position.y
                )
                // Raio ~ metade da diagonal do quadrado (lado 34)
                if dSq < 24 {
                    sq.takeDamage(1)
                    bullet.removeFromParent()
                    bulletIndicesToRemove.insert(bulletIndex)
                    if sq.parent == nil {
                        gameState.score += 10
                    }
                    continue
                }
            }

            for (enemyIndex, enemy) in enemies.enumerated() {
                guard !enemyIndicesToRemove.contains(enemyIndex) else { continue }

                let distance = hypot(
                    bullet.position.x - enemy.position.x,
                    bullet.position.y - enemy.position.y
                )
                if distance < 20 {
                    enemy.removeFromParent()
                    enemyIndicesToRemove.insert(enemyIndex)
                    bullet.removeFromParent()
                    bulletIndicesToRemove.insert(bulletIndex)
                    gameState.score += 10
                    break
                }
            }
        }

        for index in bulletIndicesToRemove.sorted(by: >) {
            bullets.remove(at: index)
        }
        for index in enemyIndicesToRemove.sorted(by: >) {
            enemies.remove(at: index)
        }
    }

    /// Inimigo mais próximo: triângulos vivos e o quadrado (se ainda tiver HP).
    func findClosestTarget(to player: PlayerNode) -> SKNode? {
        var closest: SKNode?
        var closestDistance = CGFloat.greatestFiniteMagnitude

        if let sq = squared, sq.parent != nil, sq.hp > 0 {
            let dx = sq.position.x - player.position.x
            let dy = sq.position.y - player.position.y
            closestDistance = hypot(dx, dy)
            closest = sq
        }

        for enemy in enemies where enemy.parent != nil {
            let dx = enemy.position.x - player.position.x
            let dy = enemy.position.y - player.position.y
            let distance = hypot(dx, dy)
            if distance < closestDistance {
                closestDistance = distance
                closest = enemy
            }
        }

        return closest
    }

    func updateTargetIndicator(at position: CGPoint) {
        if targetIndicator == nil {
            targetIndicator = SKShapeNode(circleOfRadius: 25)
            targetIndicator?.strokeColor = .green
            targetIndicator?.lineWidth = 2
            targetIndicator?.fillColor = .clear
            targetIndicator?.zPosition = 1
            addChild(targetIndicator!)
        }

        targetIndicator?.position = position
    }
}
