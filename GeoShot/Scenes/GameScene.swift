//
//  GameScene.swift
//  GeoShot
//
// Mapa contínuo: salas + corredores; entrada das salas de combate fecha com a borda.
// Boss só após limpar todas as salas de inimigos do andar.
//

import SpriteKit

class GameScene: SKScene {
    var gameState = GameState()
    var player: PlayerNode!
    var joystick: JoystickNode!

    var enemies: [TriangleNode] = []
    var squared: SquaredNode?
    var plusMiniboss: PlusNode?
    var pentagonBoss: PentagonNode?
    var bullets: [BulletNode] = []
    var enemyBullets: [EnemyBulletNode] = []

    var joystickTouch: UITouch?
    var fireTouch: UITouch?
    var targetIndicator: SKShapeNode?

    private var lastUpdateTime: TimeInterval = 0
    private var lastFireTime: TimeInterval = 0
    private let fireRate: TimeInterval = 0.5
    private var isFiring: Bool { fireTouch != nil }

    private var worldNode: SKNode!
    private var mapRoot: SKNode!
    private var gameCamera: SKCameraNode!
    private var hudNode: SKNode!
    private var viewportSize: CGSize = .zero
    private var currentWorldBounds: CGRect = .zero
    private let cameraFollowSmoothing: CGFloat = 14

    private var currentFloor = 1
    private var zonesById: [String: DungeonZone] = [:]
    private var passages: [DungeonPassage] = []
    private var doorNodes: [String: DungeonDoorNode] = [:]

    private var currentZoneId: String = "start"
    private var clearedCombatZoneIds: Set<String> = []
    private var activeCombatZoneId: String?
    private var bossSpawnedThisFloor = false
    private var runCompleted = false
    private var hpLabel: SKLabelNode?
    private var hpContainerNode: SKNode?
    private var timerLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?
    private var scoreIconNode: SKShapeNode?
    private var upgradesContainerNode: SKNode?
    private var lastUpgradesCount = -1
    private var elapsedTime: TimeInterval = 0
    private var playerInvulnerableTime: TimeInterval = 0

    private var roomProgressLabel: SKLabelNode?
    private var minimap: DungeonMinimapNode?

    private var currentShakeIntensity: CGFloat = 0
    private var shakeDecay: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = DungeonMapPalette.worldBackground
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        viewportSize = size
        setupCameraAndWorld()
        setupRoomProgressLabel()
        setupHPLabel()
        setupTimerLabel()
        setupScoreLabel()
        setupMinimap()
        setupUpgradesContainer()
        setupJoystick()
        spawnPlayer()
        buildFloor(1)
        snapCameraToPlayer()
    }

    // MARK: - Setup

    private func setupCameraAndWorld() {
        worldNode = SKNode()
        worldNode.name = "world"
        addChild(worldNode)

        mapRoot = SKNode()
        mapRoot.name = "mapRoot"
        worldNode.addChild(mapRoot)

        gameCamera = SKCameraNode()
        gameCamera.name = "gameCamera"
        addChild(gameCamera)
        camera = gameCamera

        hudNode = SKNode()
        hudNode.name = "hud"
        gameCamera.addChild(hudNode)
    }

    private func setupRoomProgressLabel() {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.alpha = 0.85
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: -viewportSize.width / 2 + 16, y: viewportSize.height / 2 - 12)
        label.zPosition = 20
        label.fontColor = .white
        hudNode.addChild(label)
        roomProgressLabel = label
    }

    private func setupHPLabel() {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.alpha = 0.85
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -viewportSize.width / 2 + 16, y: viewportSize.height / 2 - 38)
        label.zPosition = 20
        label.fontColor = .white
        label.text = "HP"
        hudNode.addChild(label)
        hpLabel = label
        
        let container = SKNode()
        container.zPosition = 20
        hudNode.addChild(container)
        hpContainerNode = container
        
        updateHPLabel()
    }
    
    private func updateHPLabel() {
        hpContainerNode?.removeAllChildren()
        guard let hpContainer = hpContainerNode else { return }
        
        let totalHearts = (gameState.maxHp + 1) / 2
        let startX = -viewportSize.width / 2 + 48
        let yPos = viewportSize.height / 2 - 38
        
        for i in 0..<totalHearts {
            let heartHpIndex = i * 2
            let state: HeartState
            if gameState.hp >= heartHpIndex + 2 {
                state = .full
            } else if gameState.hp == heartHpIndex + 1 {
                state = .half
            } else {
                state = .empty
            }
            
            let heart = createHeartNode(state: state)
            heart.position = CGPoint(x: startX + CGFloat(i) * 20, y: yPos)
            hpContainer.addChild(heart)
        }
    }
    
    private func createHeartNode(state: HeartState) -> SKNode {
        let container = SKNode()
        
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: 0, y: -7))
        leftPath.addLine(to: CGPoint(x: -7, y: 0))
        leftPath.addLine(to: CGPoint(x: -7, y: 4))
        leftPath.addLine(to: CGPoint(x: -4, y: 7))
        leftPath.addLine(to: CGPoint(x: 0, y: 3))
        leftPath.closeSubpath()
        
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: 0, y: -7))
        rightPath.addLine(to: CGPoint(x: 7, y: 0))
        rightPath.addLine(to: CGPoint(x: 7, y: 4))
        rightPath.addLine(to: CGPoint(x: 4, y: 7))
        rightPath.addLine(to: CGPoint(x: 0, y: 3))
        rightPath.closeSubpath()
        
        let leftHalf = SKShapeNode(path: leftPath)
        let rightHalf = SKShapeNode(path: rightPath)
        
        let fillColor = SKColor(red: 1.0, green: 0.25, blue: 0.35, alpha: 1.0)
        let emptyColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.6)
        let strokeColor = SKColor.white
        let emptyStrokeColor = SKColor.white.withAlphaComponent(0.3)
        
        leftHalf.lineWidth = 1.0
        rightHalf.lineWidth = 1.0
        
        switch state {
        case .full:
            leftHalf.fillColor = fillColor
            leftHalf.strokeColor = strokeColor
            rightHalf.fillColor = fillColor
            rightHalf.strokeColor = strokeColor
        case .half:
            leftHalf.fillColor = fillColor
            leftHalf.strokeColor = strokeColor
            rightHalf.fillColor = emptyColor
            rightHalf.strokeColor = emptyStrokeColor
        case .empty:
            leftHalf.fillColor = emptyColor
            leftHalf.strokeColor = emptyStrokeColor
            rightHalf.fillColor = emptyColor
            rightHalf.strokeColor = emptyStrokeColor
        }
        
        container.addChild(leftHalf)
        container.addChild(rightHalf)
        return container
    }

    private func setupMinimap() {
        let side = min(140, max(96, viewportSize.width * 0.2))
        let panel = CGSize(width: side, height: side)
        let map = DungeonMinimapNode(mapPixelSize: panel)
        map.position = CGPoint(
            x: viewportSize.width / 2 - 12 - panel.width,
            y: viewportSize.height / 2 - 12 - panel.height
        )
        hudNode.addChild(map)
        minimap = map
    }

    private func setupTimerLabel() {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.alpha = 0.9
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: 0, y: viewportSize.height / 2 - 12)
        label.zPosition = 20
        label.fontColor = .white
        label.text = "00:00.00"
        hudNode.addChild(label)
        timerLabel = label
    }

    private func updateTimerLabel() {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let centiseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1.0)) * 100)
        timerLabel?.text = String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    private func setupScoreLabel() {
        let yPos = viewportSize.height / 2 - 62
        
        let icon = SKShapeNode(path: createHexagonPath(radius: 6))
        icon.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        icon.strokeColor = .white
        icon.lineWidth = 1.0
        icon.position = CGPoint(x: -viewportSize.width / 2 + 22, y: yPos)
        icon.zPosition = 20
        hudNode.addChild(icon)
        scoreIconNode = icon
        
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.alpha = 0.85
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -viewportSize.width / 2 + 36, y: yPos)
        label.zPosition = 20
        label.fontColor = .white
        label.text = "0000"
        hudNode.addChild(label)
        scoreLabel = label
        
        updateScoreLabel()
    }

    private func createHexagonPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            let angle = CGFloat(i) * CGFloat.pi / 3
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    private func updateScoreLabel() {
        scoreLabel?.text = String(format: "%04d", gameState.score)
    }

    private func setupUpgradesContainer() {
        let container = SKNode()
        container.zPosition = 20
        hudNode.addChild(container)
        upgradesContainerNode = container
        updateUpgradesUI()
    }

    private func updateUpgradesUI() {
        guard let container = upgradesContainerNode else { return }
        guard gameState.upgrades.count != lastUpgradesCount else { return }
        lastUpgradesCount = gameState.upgrades.count
        container.removeAllChildren()
        
        let side = min(140, max(96, viewportSize.width * 0.2))
        let startY = viewportSize.height / 2 - 12 - side - 20
        let startX = viewportSize.width / 2 - 16
        
        for (index, upgrade) in gameState.upgrades.enumerated() {
            let slotSize: CGFloat = 26
            let spacing: CGFloat = 6
            let xPos = startX - (slotSize / 2) - CGFloat(index) * (slotSize + spacing)
            
            let slot = SKShapeNode(rectOf: CGSize(width: slotSize, height: slotSize), cornerRadius: 4)
            slot.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
            slot.strokeColor = upgrade.color
            slot.lineWidth = 1.5
            slot.position = CGPoint(x: xPos, y: startY)
            
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = upgrade.shortName
            label.fontSize = 8
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: 0)
            
            slot.addChild(label)
            container.addChild(slot)
        }
    }

    func setupJoystick() {
        joystick = JoystickNode()
        joystick.zPosition = 10
        hudNode.addChild(joystick)
    }

    func spawnPlayer() {
        player = PlayerNode(gameState: gameState)
        player.zPosition = 2
        worldNode.addChild(player)
    }

    // MARK: - Mapa do andar

    private func buildFloor(_ floor: Int) {
        currentFloor = floor
        clearedCombatZoneIds.removeAll()
        activeCombatZoneId = nil
        bossSpawnedThisFloor = false
        currentZoneId = "start"

        clearCombatEntities()
        mapRoot.removeAllChildren()
        doorNodes.removeAll()

        zonesById = DungeonFloorPlan.zonesById(for: floor)
        passages = DungeonFloorPlan.passages(for: floor)
        currentWorldBounds = DungeonFloorPlan.worldBounds(for: floor)

        drawMapGeometry()
        createDoors()
        refreshDoorStates()

        minimap?.rebuild(for: floor)
        minimap?.setClearedRooms(clearedCombatZoneIds)
        minimap?.setHighlightedRoom(id: currentZoneId)

        if let start = zonesById["start"] {
            player.position = CGPoint(x: start.walkBounds.midX, y: start.walkBounds.midY)
        }
        updateHUD()
        snapCameraToPlayer()
    }

    private func drawMapGeometry() {
        let outer = SKShapeNode(rect: currentWorldBounds)
        outer.fillColor = DungeonMapPalette.worldBackground
        outer.strokeColor = .clear
        outer.zPosition = -3
        mapRoot.addChild(outer)

        func getSegments(start: CGFloat, end: CGFloat, gaps: [(CGFloat, CGFloat)]) -> [(CGFloat, CGFloat)] {
            var result: [(CGFloat, CGFloat)] = []
            let sortedGaps = gaps
                .map { (min($0.0, $0.1), max($0.0, $0.1)) }
                .filter { $0.1 > start && $0.0 < end }
                .sorted { $0.0 < $1.0 }
            
            var current = start
            for (gStart, gEnd) in sortedGaps {
                if gStart > current {
                    result.append((current, gStart))
                }
                current = max(current, gEnd)
            }
            if current < end {
                result.append((current, end))
            }
            return result
        }

        func addWallBody(from start: CGPoint, to end: CGPoint) {
            let thickness: CGFloat = max(DungeonMapPalette.roomStrokeWidth + 8, 14)
            let wallNode = SKNode()
            wallNode.zPosition = -1

            if abs(start.y - end.y) < 0.5 {
                let width = abs(end.x - start.x) + thickness
                wallNode.position = CGPoint(x: (start.x + end.x) / 2, y: start.y)
                wallNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: thickness))
            } else {
                let height = abs(end.y - start.y) + thickness
                wallNode.position = CGPoint(x: start.x, y: (start.y + end.y) / 2)
                wallNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: thickness, height: height))
            }

            wallNode.physicsBody?.isDynamic = false
            wallNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
            wallNode.physicsBody?.contactTestBitMask = PhysicsCategory.bullet
            wallNode.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
            mapRoot.addChild(wallNode)
        }

        for zone in zonesById.values.sorted(by: { $0.floorRect.minY > $1.floorRect.minY }) {
            // 1. Desenhar o chão da zona (sem borda)
            let floor = SKShapeNode(rect: zone.floorRect)
            floor.zPosition = -2
            floor.strokeColor = .clear

            switch zone.kind {
            case .start:
                floor.fillColor = DungeonMapPalette.startRoomFill
            case .corridor:
                floor.fillColor = DungeonMapPalette.corridorFill
            case .combat:
                floor.fillColor = DungeonMapPalette.roomFill
            case .boss:
                floor.fillColor = DungeonMapPalette.bossRoomFill
            }
            mapRoot.addChild(floor)

            // 2. Desenhar as bordas
            let borderPath = CGMutablePath()
            let rect = zone.floorRect

            if zone.kind == .corridor {
                // Desenhar apenas as paredes laterais do corredor
                let isVertical = rect.width < rect.height
                if isVertical {
                    borderPath.move(to: CGPoint(x: rect.minX, y: rect.minY))
                    borderPath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                    addWallBody(from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.minX, y: rect.maxY))
                    borderPath.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                    borderPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                    addWallBody(from: CGPoint(x: rect.maxX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.maxY))
                } else {
                    borderPath.move(to: CGPoint(x: rect.minX, y: rect.minY))
                    borderPath.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                    addWallBody(from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.minY))
                    borderPath.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                    borderPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                    addWallBody(from: CGPoint(x: rect.minX, y: rect.maxY), to: CGPoint(x: rect.maxX, y: rect.maxY))
                }
            } else {
                // Desenhar as bordas da sala com aberturas (gaps) onde houver passagens
                let minX = rect.minX
                let maxX = rect.maxX
                let minY = rect.minY
                let maxY = rect.maxY

                let roomPassages = passages.filter { $0.connects(zone.id) }
                
                var bottomGaps: [(CGFloat, CGFloat)] = []
                var topGaps: [(CGFloat, CGFloat)] = []
                var leftGaps: [(CGFloat, CGFloat)] = []
                var rightGaps: [(CGFloat, CGFloat)] = []
                
                let tolerance: CGFloat = 2.0
                for p in roomPassages {
                    let pRect = p.rect
                    
                    // Borda inferior
                    if pRect.minY - tolerance <= minY && pRect.maxY + tolerance >= minY {
                        bottomGaps.append((pRect.minX, pRect.maxX))
                    }
                    // Borda superior
                    if pRect.minY - tolerance <= maxY && pRect.maxY + tolerance >= maxY {
                        topGaps.append((pRect.minX, pRect.maxX))
                    }
                    // Borda esquerda
                    if pRect.minX - tolerance <= minX && pRect.maxX + tolerance >= minX {
                        leftGaps.append((pRect.minY, pRect.maxY))
                    }
                    // Borda direita
                    if pRect.minX - tolerance <= maxX && pRect.maxX + tolerance >= maxX {
                        rightGaps.append((pRect.minY, pRect.maxY))
                    }
                }

                for (x1, x2) in getSegments(start: minX, end: maxX, gaps: bottomGaps) {
                    borderPath.move(to: CGPoint(x: x1, y: minY))
                    borderPath.addLine(to: CGPoint(x: x2, y: minY))
                    addWallBody(from: CGPoint(x: x1, y: minY), to: CGPoint(x: x2, y: minY))
                }
                for (x1, x2) in getSegments(start: minX, end: maxX, gaps: topGaps) {
                    borderPath.move(to: CGPoint(x: x1, y: maxY))
                    borderPath.addLine(to: CGPoint(x: x2, y: maxY))
                    addWallBody(from: CGPoint(x: x1, y: maxY), to: CGPoint(x: x2, y: maxY))
                }
                for (y1, y2) in getSegments(start: minY, end: maxY, gaps: leftGaps) {
                    borderPath.move(to: CGPoint(x: minX, y: y1))
                    borderPath.addLine(to: CGPoint(x: minX, y: y2))
                    addWallBody(from: CGPoint(x: minX, y: y1), to: CGPoint(x: minX, y: y2))
                }
                for (y1, y2) in getSegments(start: minY, end: maxY, gaps: rightGaps) {
                    borderPath.move(to: CGPoint(x: maxX, y: y1))
                    borderPath.addLine(to: CGPoint(x: maxX, y: y2))
                    addWallBody(from: CGPoint(x: maxX, y: y1), to: CGPoint(x: maxX, y: y2))
                }
            }

            let borderNode = SKShapeNode(path: borderPath)
            borderNode.zPosition = -1
            borderNode.strokeColor = DungeonMapPalette.roomStroke
            borderNode.lineWidth = DungeonMapPalette.roomStrokeWidth
            mapRoot.addChild(borderNode)
        }
    }

    private func createDoors() {
        for passage in passages {
            let door = DungeonDoorNode(passage: passage, zonesById: zonesById)
            mapRoot.addChild(door)
            doorNodes[passage.id] = door
        }
    }

    private func refreshDoorStates() {
        let allCombatCleared = DungeonFloorPlan.requiredCombatZoneIds(for: currentFloor)
            .isSubset(of: clearedCombatZoneIds)

        for passage in passages {
            guard let door = doorNodes[passage.id] else { continue }

            if DungeonFloorPlan.involvesBoss(passage) {
                door.setOpen(allCombatCleared, animated: false)
                continue
            }

            if let active = activeCombatZoneId, passage.connects(active) {
                door.setOpen(false, animated: false)
                continue
            }

            door.setOpen(true, animated: false)
        }
    }

    private func closeDoors(forCombatZone zoneId: String) {
        for passage in DungeonFloorPlan.passages(forZone: zoneId, floor: currentFloor) {
            doorNodes[passage.id]?.setOpen(false, animated: true)
        }
    }

    private func openDoors(forCombatZone zoneId: String) {
        for passage in DungeonFloorPlan.passages(forZone: zoneId, floor: currentFloor) {
            if DungeonFloorPlan.involvesBoss(passage) {
                let cleared = DungeonFloorPlan.requiredCombatZoneIds(for: currentFloor)
                    .isSubset(of: clearedCombatZoneIds)
                doorNodes[passage.id]?.setOpen(cleared, animated: true)
            } else {
                doorNodes[passage.id]?.setOpen(true, animated: true)
            }
        }
    }

    // MARK: - Zonas e movimento

    private func zoneId(at point: CGPoint) -> String? {
        DungeonFloorPlan.zoneId(at: point, floor: currentFloor)
    }

    private func handleZoneChange(from previous: String, to newZone: String) {
        guard newZone != previous else { return }

        currentZoneId = newZone
        minimap?.setHighlightedRoom(id: newZone)
        updateHUD()

        guard let zone = zonesById[newZone] else { return }

        if zone.kind == .combat, !clearedCombatZoneIds.contains(newZone) {
            beginCombat(in: newZone)
        }

        if zone.kind == .boss, allRequiredCombatCleared() {
            spawnBossIfNeeded(in: zone)
        }
    }

    private func allRequiredCombatCleared() -> Bool {
        DungeonFloorPlan.requiredCombatZoneIds(for: currentFloor)
            .isSubset(of: clearedCombatZoneIds)
    }

    private func beginCombat(in zoneId: String) {
        guard activeCombatZoneId != zoneId else { return }
        activeCombatZoneId = zoneId
        
        // Empurrar o jogador para dentro da área jogável da sala para evitar ficar preso na porta
        if let zone = zonesById[zoneId], let player = player {
            let bounds = zone.walkBounds
            player.position = CGPoint(
                x: min(max(player.position.x, bounds.minX), bounds.maxX),
                y: min(max(player.position.y, bounds.minY), bounds.maxY)
            )
        }
        
        closeDoors(forCombatZone: zoneId)
        spawnCombat(in: zoneId)
    }

    private func spawnCombat(in zoneId: String) {
        guard let zone = zonesById[zoneId], zone.kind == .combat else { return }
        clearCombatEntities()

        let diff = DungeonMap.difficulty(forFloor: currentFloor)
        let b = zone.walkBounds.insetBy(dx: 36, dy: 36)

        for _ in 0..<diff.combatTriangleCount {
            let enemy = TriangleNode(gameState: gameState, moveSpeed: diff.triangleMoveSpeed)
            enemy.position = CGPoint(
                x: CGFloat.random(in: b.minX...b.maxX),
                y: CGFloat.random(in: b.minY...b.maxY)
            )
            worldNode.addChild(enemy)
            enemies.append(enemy)
        }

        if diff.combatSquaredCount >= 1 {
            let sq = SquaredNode(gameState: gameState, moveSpeed: diff.squaredMoveSpeed)
            sq.position = CGPoint(
                x: CGFloat.random(in: b.minX...b.maxX),
                y: CGFloat.random(in: b.minY...b.maxY)
            )
            worldNode.addChild(sq)
            squared = sq
        }
    }

    private func spawnBossIfNeeded(in zone: DungeonZone) {
        guard !bossSpawnedThisFloor, zone.kind == .boss else { return }
        bossSpawnedThisFloor = true

        let center = CGPoint(x: zone.walkBounds.midX, y: zone.walkBounds.midY + 40)

        if currentFloor == 1 {
            let plus = PlusNode(gameState: gameState)
            plus.position = center
            worldNode.addChild(plus)
            plusMiniboss = plus
        } else {
            let boss = PentagonNode(gameState: gameState)
            boss.position = center
            worldNode.addChild(boss)
            pentagonBoss = boss
        }
    }

    private func onCombatZoneCleared(_ zoneId: String) {
        clearedCombatZoneIds.insert(zoneId)
        activeCombatZoneId = nil
        openDoors(forCombatZone: zoneId)
        refreshDoorStates()
        minimap?.setClearedRooms(clearedCombatZoneIds)
        updateHUD()
    }

    private func onBossDefeated() {
        if currentFloor == 1 {
            let wait = SKAction.wait(forDuration: 1)
            let next = SKAction.run { [weak self] in
                self?.buildFloor(2)
            }
            run(SKAction.sequence([wait, next]))
        } else {
            showRunVictory()
        }
    }

    private func updateHUD() {
        guard let zone = zonesById[currentZoneId] else { return }
        let cleared = clearedCombatZoneIds.count
        let required = DungeonFloorPlan.requiredCombatZoneIds(for: currentFloor).count
        var suffix = zone.displayTitle
        if zone.kind == .combat {
            suffix += clearedCombatZoneIds.contains(zone.id) ? " · Limpa" : " · Combate"
        } else if zone.kind == .boss {
            suffix += bossSpawnedThisFloor ? " · Boss" : (allRequiredCombatCleared() ? " · Aberta" : " · Bloqueada")
        }
        roomProgressLabel?.text = "Andar \(currentFloor)  \(suffix)  (\(cleared)/\(required))"
    }

    // MARK: - Câmara

    private func snapCameraToPlayer() {
        gameCamera.position = clampedCameraPosition(focus: player.position)
    }

    private func updateCameraFollow(deltaTime: TimeInterval) {
        let target = clampedCameraPosition(focus: player.position)
        
        var basePosition = gameCamera.position
        if deltaTime > 0 {
            let t = min(1, cameraFollowSmoothing * CGFloat(deltaTime))
            basePosition = CGPoint(
                x: gameCamera.position.x + (target.x - gameCamera.position.x) * t,
                y: gameCamera.position.y + (target.y - gameCamera.position.y) * t
            )
        } else {
            basePosition = target
        }
        
        if currentShakeIntensity > 0 {
            let shakeX = CGFloat.random(in: -currentShakeIntensity...currentShakeIntensity)
            let shakeY = CGFloat.random(in: -currentShakeIntensity...currentShakeIntensity)
            gameCamera.position = CGPoint(x: basePosition.x + shakeX, y: basePosition.y + shakeY)
            
            currentShakeIntensity -= shakeDecay * CGFloat(deltaTime)
            if currentShakeIntensity < 0 {
                currentShakeIntensity = 0
            }
        } else {
            gameCamera.position = basePosition
        }
    }

    private func triggerScreenShake(intensity: CGFloat, duration: TimeInterval) {
        currentShakeIntensity = intensity
        if duration > 0 {
            shakeDecay = intensity / CGFloat(duration)
        } else {
            shakeDecay = intensity
        }
    }

    private func spawnGeometricExplosion(at position: CGPoint, color: SKColor, shapeType: String) {
        let particleCount = 12
        for _ in 0..<particleCount {
            let particle = SKShapeNode()
            let path = CGMutablePath()
            
            switch shapeType {
            case "enemy", "triangle":
                path.move(to: CGPoint(x: 0, y: 6))
                path.addLine(to: CGPoint(x: -5, y: -3))
                path.addLine(to: CGPoint(x: 5, y: -3))
                path.closeSubpath()
            case "squared", "square":
                let side: CGFloat = 8
                path.addRect(CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
            case "plusMiniboss", "plus":
                let thick: CGFloat = 3
                let span: CGFloat = 9
                path.addRect(CGRect(x: -thick / 2, y: -span / 2, width: thick, height: span))
                path.addRect(CGRect(x: -span / 2, y: -thick / 2, width: span, height: thick))
            case "pentagonBoss", "pentagon":
                let radius: CGFloat = 6
                let startAngle = CGFloat.pi / 2 + CGFloat.pi / 5
                for i in 0..<5 {
                    let angle = startAngle + CGFloat(i) * 2 * CGFloat.pi / 5
                    let x = radius * cos(angle)
                    let y = radius * sin(angle)
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
            case "player", "kite":
                path.move(to: CGPoint(x: 0, y: 4))
                path.addLine(to: CGPoint(x: 8, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -4))
                path.addLine(to: CGPoint(x: -4, y: 0))
                path.closeSubpath()
            default:
                path.addEllipse(in: CGRect(x: -3, y: -3, width: 6, height: 6))
            }
            
            particle.path = path
            particle.fillColor = color
            particle.strokeColor = .white
            particle.lineWidth = 1.0
            particle.position = position
            particle.zPosition = 5
            
            worldNode.addChild(particle)
            
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 40...90)
            let duration = Double.random(in: 0.4...0.7)
            
            let moveDest = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let moveAction = SKAction.move(to: moveDest, duration: duration)
            moveAction.timingMode = .easeOut
            
            let rotateAction = SKAction.rotate(byAngle: CGFloat.random(in: -CGFloat.pi * 2...CGFloat.pi * 2), duration: duration)
            let fadeOutAction = SKAction.fadeOut(withDuration: duration)
            let scaleAction = SKAction.scale(to: 0.1, duration: duration)
            
            let group = SKAction.group([moveAction, rotateAction, fadeOutAction, scaleAction])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            
            particle.run(sequence)
        }
    }

    private func clampedCameraPosition(focus: CGPoint) -> CGPoint {
        let halfW = viewportSize.width / 2
        let halfH = viewportSize.height / 2
        let minX = currentWorldBounds.minX + halfW
        let maxX = currentWorldBounds.maxX - halfW
        let minY = currentWorldBounds.minY + halfH
        let maxY = currentWorldBounds.maxY - halfH

        var x = focus.x
        var y = focus.y
        if minX > maxX { x = currentWorldBounds.midX } else { x = min(max(x, minX), maxX) }
        if minY > maxY { y = currentWorldBounds.midY } else { y = min(max(y, minY), maxY) }
        return CGPoint(x: x, y: y)
    }

    // MARK: - Combate / entidades

    private func clearCombatEntities() {
        for e in enemies where e.parent != nil { e.removeFromParent() }
        enemies.removeAll()
        squared?.removeFromParent()
        squared = nil
        plusMiniboss?.removeFromParent()
        plusMiniboss = nil
        pentagonBoss?.removeFromParent()
        pentagonBoss = nil
        for b in bullets where b.parent != nil { b.removeFromParent() }
        bullets.removeAll()
        for eb in enemyBullets where eb.parent != nil { eb.removeFromParent() }
        enemyBullets.removeAll()
        targetIndicator?.removeFromParent()
        targetIndicator = nil
    }

    private func isCombatClearInActiveZone() -> Bool {
        if enemies.contains(where: { $0.parent != nil }) { return false }
        if let sq = squared, sq.parent != nil, sq.hp > 0 { return false }
        return true
    }

    private func isBossDead() -> Bool {
        if let plus = plusMiniboss {
            return plus.parent == nil || plus.hp <= 0
        }
        if let boss = pentagonBoss {
            return boss.parent == nil || boss.hp <= 0
        }
        return false
    }

    private func evaluateProgress() {
        guard !runCompleted else { return }

        if let active = activeCombatZoneId, isCombatClearInActiveZone() {
            onCombatZoneCleared(active)
        }

        if bossSpawnedThisFloor, isBossDead() {
            onBossDefeated()
        }
    }

    // MARK: - Input

    func isInJoystickArea(_ p: CGPoint) -> Bool { p.x < -viewportSize.width * 0.1 }
    func isInFireArea(_ p: CGPoint) -> Bool { p.x > viewportSize.width * 0.1 }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let loc = t.location(in: gameCamera)
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
        joystick.update(to: jt.location(in: gameCamera))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if t == joystickTouch { joystickTouch = nil; joystick.disappear() }
            if t == fireTouch { fireTouch = nil }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        guard let player = player, let joystick = joystick else { return }

        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if player.isAlive && !runCompleted {
            elapsedTime = gameState.elapsedTime + deltaTime
            gameState.elapsedTime = elapsedTime
            updateTimerLabel()
            updateScoreLabel()
            updateUpgradesUI()
        }

        let movementAngle: CGFloat? = joystick.direction != .zero
            ? atan2(joystick.direction.dy, joystick.direction.dx)
            : nil

        if player.isAlive {
            if joystick.direction != .zero {
                let vx = joystick.direction.dx * player.moveSpeed
                let vy = joystick.direction.dy * player.moveSpeed
                player.physicsBody?.velocity = CGVector(dx: vx, dy: vy)
            } else {
                player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            }
        } else {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        }

        updateCameraFollow(deltaTime: deltaTime)

        if let squared = squared, squared.parent != nil {
            squared.move(towards: player.position, deltaTime: deltaTime)
            if player.isAlive && !runCompleted {
                let newBullets = squared.updateAttack(targetPosition: player.position, deltaTime: deltaTime)
                for b in newBullets {
                    worldNode.addChild(b)
                    enemyBullets.append(b)
                }
            }
        }
        if let plus = plusMiniboss, plus.parent != nil {
            plus.move(towards: player.position, deltaTime: deltaTime)
            if player.isAlive && !runCompleted {
                let newBullets = plus.updateAttack(targetPosition: player.position, deltaTime: deltaTime)
                for b in newBullets {
                    worldNode.addChild(b)
                    enemyBullets.append(b)
                }
            }
        }
        if let boss = pentagonBoss, boss.parent != nil {
            boss.move(towards: player.position, deltaTime: deltaTime)
            if player.isAlive && !runCompleted {
                let newBullets = boss.updateAttack(targetPosition: player.position, deltaTime: deltaTime)
                for b in newBullets {
                    worldNode.addChild(b)
                    enemyBullets.append(b)
                }
            }
        }
        for enemy in enemies where enemy.parent != nil {
            enemy.move(towards: player.position, deltaTime: deltaTime)
        }

        if let target = findClosestTarget(to: player) {
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
            targetIndicator?.removeFromParent()
            targetIndicator = nil
            if let movementAngle = movementAngle {
                player.zRotation = movementAngle
            }
        }

        if isFiring && currentTime - lastFireTime >= fireRate {
            let bullet = BulletNode(position: player.position, direction: player.fireDirection)
            worldNode.addChild(bullet)
            bullets.append(bullet)
            lastFireTime = currentTime
        }

        bullets.removeAll { bullet in
            if bullet.isOutside(bounds: currentWorldBounds) {
                bullet.removeFromParent()
                return true
            }
            return false
        }
        bullets.removeAll { $0.parent == nil }

        enemyBullets.removeAll { bullet in
            if bullet.isOutside(bounds: currentWorldBounds) {
                bullet.removeFromParent()
                return true
            }
            return false
        }
        enemyBullets.removeAll { $0.parent == nil }

        enemies.removeAll { $0.parent == nil }
        if squared?.parent == nil { squared = nil }
        if plusMiniboss?.parent == nil { plusMiniboss = nil }
        if pentagonBoss?.parent == nil { pentagonBoss = nil }

        checkPlayerEnemyCollisions(deltaTime: deltaTime)
        evaluateProgress()
    }

    override func didSimulatePhysics() {
        super.didSimulatePhysics()

        guard let player = player, player.isAlive, !runCompleted else { return }
        if let newZone = zoneId(at: player.position) {
            handleZoneChange(from: currentZoneId, to: newZone)
        }
    }

    private func showRunVictory() {
        runCompleted = true
        roomProgressLabel?.text = "Vitória — dungeon concluída"
        
        let wait = SKAction.wait(forDuration: 1.5)
        let transition = SKAction.run { [weak self] in
            guard let self = self, let skView = self.view else { return }
            let endScene = EndScene(size: self.size, isVictory: true, score: self.gameState.score, time: self.elapsedTime, damageDealt: self.gameState.damageDealt)
            endScene.scaleMode = .resizeFill
            endScene.anchorPoint = CGPoint(x: 0, y: 0)
            let fade = SKTransition.fade(withDuration: 1.2)
            skView.presentScene(endScene, transition: fade)
        }
        run(SKAction.sequence([wait, transition]))
    }

    private func showGameOver() {
        runCompleted = true
        
        let wait = SKAction.wait(forDuration: 1.5)
        let transition = SKAction.run { [weak self] in
            guard let self = self, let skView = self.view else { return }
            let endScene = EndScene(size: self.size, isVictory: false, score: self.gameState.score, time: self.elapsedTime, damageDealt: self.gameState.damageDealt)
            endScene.scaleMode = .resizeFill
            endScene.anchorPoint = CGPoint(x: 0, y: 0)
            let fade = SKTransition.fade(withDuration: 1.2)
            skView.presentScene(endScene, transition: fade)
        }
        run(SKAction.sequence([wait, transition]))
    }

    private func checkPlayerEnemyCollisions(deltaTime: TimeInterval) {
        // Player-enemy collisions are now handled by physics contact delegate.
        // Update invulnerability blink while invulnerable.
        guard player.isAlive && !runCompleted else { return }
        if playerInvulnerableTime > 0 {
            playerInvulnerableTime -= deltaTime
            let blink = playerInvulnerableTime.truncatingRemainder(dividingBy: 0.15) > 0.07
            player.alpha = blink ? 0.3 : 1.0
            if playerInvulnerableTime <= 0 { player.alpha = 1.0 }
        }
    }
    
    private func playerTakeDamage(_ amount: Int) {
        guard gameState.isAlive && playerInvulnerableTime <= 0 else { return }

        gameState.takeDamage(amount)
        player.maxHp = gameState.maxHp
        player.setHP(gameState.hp)
        updateHPLabel()
        
        // Flash red visual effect
        let redFlash = SKAction.sequence([
            SKAction.run { [weak self] in self?.player.fillColor = .red },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in self?.player.fillColor = .cyan }
        ])
        player.run(redFlash)
        
        playerInvulnerableTime = 1.2 // 1.2 seconds of invulnerability
        
        // Shake screen on damage
        triggerScreenShake(intensity: 15.0, duration: 0.35)
        
        if gameState.hp <= 0 {
            // Player death!
            let explosion = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.spawnGeometricExplosion(at: self.player.position, color: .cyan, shapeType: "player")
                self.player.removeFromParent()
                // Show game over end screen
                self.showGameOver()
            }
            run(explosion)
        }
    }

    func findClosestTarget(to player: PlayerNode) -> SKNode? {
        var closest: SKNode?
        var closestDistance = CGFloat.greatestFiniteMagnitude

        func consider(_ node: SKNode?, alive: Bool) {
            guard let node = node, alive else { return }
            let d = hypot(node.position.x - player.position.x, node.position.y - player.position.y)
            if d < closestDistance { closestDistance = d; closest = node }
        }

        if let sq = squared, sq.parent != nil, sq.hp > 0 { consider(sq, alive: true) }
        if let plus = plusMiniboss, plus.parent != nil, plus.hp > 0 { consider(plus, alive: true) }
        if let boss = pentagonBoss, boss.parent != nil, boss.hp > 0 { consider(boss, alive: true) }
        for enemy in enemies where enemy.parent != nil { consider(enemy, alive: true) }

        return closest
    }

    func updateTargetIndicator(at position: CGPoint) {
        if targetIndicator == nil {
            targetIndicator = SKShapeNode(circleOfRadius: 25)
            targetIndicator?.strokeColor = .green
            targetIndicator?.lineWidth = 2
            targetIndicator?.fillColor = .clear
            targetIndicator?.zPosition = 1
            if let t = targetIndicator { worldNode.addChild(t) }
        }
        targetIndicator?.position = position
    }
}

// MARK: - Physics contact handling
extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        let mask = a.categoryBitMask | b.categoryBitMask

        switch mask {
        case PhysicsCategory.bullet | PhysicsCategory.enemy:
            let bulletBody = a.categoryBitMask == PhysicsCategory.bullet ? a : b
            let enemyBody = a.categoryBitMask == PhysicsCategory.enemy ? a : b
            if let bulletNode = bulletBody.node as? SKNode { bulletNode.removeFromParent() }
            if let enemyNode = enemyBody.node as? EnemyNode {
                let wasAlive = enemyNode.isAlive
                let name = enemyNode.name ?? "enemy"
                let pos = enemyNode.position
                let color = enemyNode.fillColor
                
                enemyNode.takeDamage(1)
                gameState.addDamage(1)
                
                if wasAlive && !enemyNode.isAlive {
                    spawnGeometricExplosion(at: pos, color: color, shapeType: name)
                    let shakeIntensity: CGFloat = (name == "plusMiniboss" || name == "pentagonBoss") ? 12 : 3
                    let shakeDuration: TimeInterval = (name == "plusMiniboss" || name == "pentagonBoss") ? 0.4 : 0.15
                    triggerScreenShake(intensity: shakeIntensity, duration: shakeDuration)
                }
            }

        case PhysicsCategory.bullet | PhysicsCategory.wall:
            // Remove bullet on wall hit
            if a.categoryBitMask == PhysicsCategory.bullet { a.node?.removeFromParent() }
            if b.categoryBitMask == PhysicsCategory.bullet { b.node?.removeFromParent() }

        case PhysicsCategory.enemyBullet | PhysicsCategory.player:
            let bulletBody = a.categoryBitMask == PhysicsCategory.enemyBullet ? a : b
            if let bulletNode = bulletBody.node as? EnemyBulletNode {
                playerTakeDamage(bulletNode.damage)
                bulletNode.removeFromParent()
            }

        case PhysicsCategory.enemyBullet | PhysicsCategory.wall:
            if a.categoryBitMask == PhysicsCategory.enemyBullet { a.node?.removeFromParent() }
            if b.categoryBitMask == PhysicsCategory.enemyBullet { b.node?.removeFromParent() }

        case PhysicsCategory.player | PhysicsCategory.enemy:
            // Player hit by enemy
            playerTakeDamage(1)

        default:
            break
        }
    }
}

enum HeartState {
    case full
    case half
    case empty
}
