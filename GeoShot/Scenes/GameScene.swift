//
//  GameScene.swift
//  GeoShot
//
// CENA PRINCIPAL DO JOGO
// - Mapa da dungeon: Andar 1 (3 combates + Plus), Andar 2 (3 combates + Pentagon)
// - Auto-aim, colisões, progressão de sala
//

import SpriteKit

class GameScene: SKScene {
    var gameState = GameState()
    var player: PlayerNode!
    var joystick: JoystickNode!

    /// Inimigos da sala atual (triângulos).
    var enemies: [TriangleNode] = []
    /// Opcional em salas de combate do andar 2.
    var squared: SquaredNode?
    var plusMiniboss: PlusNode?
    var pentagonBoss: PentagonNode?

    var bullets: [BulletNode] = []

    var joystickTouch: UITouch?
    var fireTouch: UITouch?

    private var lastUpdateTime: TimeInterval = 0
    private var lastFireTime: TimeInterval = 0
    private let fireRate: TimeInterval = 0.5

    var targetIndicator: SKShapeNode?

    private var isFiring: Bool { fireTouch != nil }

    private let roomSteps = DungeonMap.runSequence
    private var currentStepIndex = 0
    private var isAdvancingRoom = false
    private var runCompleted = false

    private var roomProgressLabel: SKLabelNode?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.05, alpha: 1)
        setupRoomProgressLabel()
        setupJoystick()
        spawnPlayer()
        loadCurrentRoom()
    }

    private func setupRoomProgressLabel() {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.alpha = 0.85
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: 16, y: size.height - 12)
        label.zPosition = 20
        label.fontColor = .white
        addChild(label)
        roomProgressLabel = label
    }

    private func updateRoomProgressLabel(for step: DungeonRoomStep) {
        let suffix: String
        switch step.kind {
        case .combat:
            suffix = "Combate"
        case .minibossPlus:
            suffix = "Miniboss +"
        case .bossPentagon:
            suffix = "Boss"
        }
        roomProgressLabel?.text = "Andar \(step.floor)  Sala \(step.roomNumberOnFloor)/4  ·  \(suffix)"
    }

    /// Remove inimigos e bosses da sala; limpa balas em jogo.
    private func clearCombatEntities() {
        for e in enemies where e.parent != nil {
            e.removeFromParent()
        }
        enemies.removeAll()

        squared?.removeFromParent()
        squared = nil

        plusMiniboss?.removeFromParent()
        plusMiniboss = nil

        pentagonBoss?.removeFromParent()
        pentagonBoss = nil

        for b in bullets where b.parent != nil {
            b.removeFromParent()
        }
        bullets.removeAll()

        targetIndicator?.removeFromParent()
        targetIndicator = nil
    }

    private func loadCurrentRoom() {
        guard currentStepIndex < roomSteps.count else { return }

        clearCombatEntities()

        let step = roomSteps[currentStepIndex]
        updateRoomProgressLabel(for: step)

        let diff = DungeonMap.difficulty(forFloor: step.floor)

        switch step.kind {
        case .combat:
            spawnCombatRoom(difficulty: diff)
        case .minibossPlus:
            let plus = PlusNode()
            plus.position = CGPoint(x: size.width * 0.5, y: size.height * 0.58)
            addChild(plus)
            plusMiniboss = plus
        case .bossPentagon:
            let boss = PentagonNode()
            boss.position = CGPoint(x: size.width * 0.5, y: size.height * 0.58)
            addChild(boss)
            pentagonBoss = boss
        }

        player.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
    }

    private func spawnCombatRoom(difficulty: FloorDifficulty) {
        for _ in 0..<difficulty.combatTriangleCount {
            let enemy = TriangleNode(gameState: gameState, moveSpeed: difficulty.triangleMoveSpeed)
            enemy.position = CGPoint(
                x: CGFloat.random(in: 100...(size.width - 100)),
                y: CGFloat.random(in: 100...(size.height - 100))
            )
            addChild(enemy)
            enemies.append(enemy)
        }

        if difficulty.combatSquaredCount >= 1 {
            let sq = SquaredNode(moveSpeed: difficulty.squaredMoveSpeed)
            sq.position = CGPoint(
                x: CGFloat.random(in: 120...(size.width - 120)),
                y: CGFloat.random(in: 120...(size.height - 120))
            )
            addChild(sq)
            squared = sq
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

        if let plus = plusMiniboss, plus.parent != nil {
            plus.move(towards: player.position, deltaTime: deltaTime)
        }

        if let boss = pentagonBoss, boss.parent != nil {
            boss.move(towards: player.position, deltaTime: deltaTime)
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
        evaluateRoomProgress()
    }

    private func evaluateRoomProgress() {
        guard !isAdvancingRoom, !runCompleted else { return }
        guard isCurrentRoomClear() else { return }

        let step = roomSteps[currentStepIndex]
        if step.isLastStep {
            showRunVictory()
            return
        }

        isAdvancingRoom = true
        let wait = SKAction.wait(forDuration: 0.75)
        let advance = SKAction.run { [weak self] in
            self?.goToNextRoom()
        }
        run(SKAction.sequence([wait, advance]))
    }

    private func goToNextRoom() {
        isAdvancingRoom = false
        currentStepIndex += 1
        loadCurrentRoom()
    }

    private func showRunVictory() {
        runCompleted = true
        roomProgressLabel?.text = "Vitória — dungeon concluída"

        let banner = SKLabelNode(fontNamed: "Menlo-Bold")
        banner.text = "Vitória!"
        banner.fontSize = 28
        banner.fontColor = .green
        banner.position = CGPoint(x: size.width / 2, y: size.height / 2)
        banner.zPosition = 25
        addChild(banner)
    }

    private func isCurrentRoomClear() -> Bool {
        if enemies.contains(where: { $0.parent != nil }) {
            return false
        }
        if let sq = squared, sq.parent != nil, sq.hp > 0 {
            return false
        }
        if let plus = plusMiniboss, plus.parent != nil, plus.hp > 0 {
            return false
        }
        if let boss = pentagonBoss, boss.parent != nil, boss.hp > 0 {
            return false
        }
        return true
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
                if dSq < 24 {
                    sq.takeDamage(1)
                    bullet.removeFromParent()
                    bulletIndicesToRemove.insert(bulletIndex)
                    if sq.parent == nil {
                        gameState.score += 10
                        squared = nil
                    }
                    continue
                }
            }

            if let plus = plusMiniboss, plus.parent != nil, plus.hp > 0 {
                let d = hypot(
                    bullet.position.x - plus.position.x,
                    bullet.position.y - plus.position.y
                )
                if d < 28 {
                    plus.takeDamage(1)
                    bullet.removeFromParent()
                    bulletIndicesToRemove.insert(bulletIndex)
                    if plus.parent == nil {
                        gameState.score += 50
                        plusMiniboss = nil
                    }
                    continue
                }
            }

            if let boss = pentagonBoss, boss.parent != nil, boss.hp > 0 {
                let d = hypot(
                    bullet.position.x - boss.position.x,
                    bullet.position.y - boss.position.y
                )
                if d < 26 {
                    boss.takeDamage(1)
                    bullet.removeFromParent()
                    bulletIndicesToRemove.insert(bulletIndex)
                    if boss.parent == nil {
                        gameState.score += 100
                        pentagonBoss = nil
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

    /// Alvo mais próximo: triângulos, quadrado, Plus ou Pentagon.
    func findClosestTarget(to player: PlayerNode) -> SKNode? {
        var closest: SKNode?
        var closestDistance = CGFloat.greatestFiniteMagnitude

        func consider(_ node: SKNode?, alive: Bool) {
            guard let node = node, alive else { return }
            let dx = node.position.x - player.position.x
            let dy = node.position.y - player.position.y
            let distance = hypot(dx, dy)
            if distance < closestDistance {
                closestDistance = distance
                closest = node
            }
        }

        if let sq = squared, sq.parent != nil, sq.hp > 0 {
            consider(sq, alive: true)
        }

        if let plus = plusMiniboss, plus.parent != nil, plus.hp > 0 {
            consider(plus, alive: true)
        }

        if let boss = pentagonBoss, boss.parent != nil, boss.hp > 0 {
            consider(boss, alive: true)
        }

        for enemy in enemies where enemy.parent != nil {
            consider(enemy, alive: true)
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
