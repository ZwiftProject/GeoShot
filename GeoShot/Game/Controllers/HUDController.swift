import SpriteKit

final class HUDController {
    private weak var scene: GameScene?
    private weak var hudRoot: SKNode?
    private let viewportSize: CGSize

    private(set) var joystick: JoystickNode?
    private var hpLabel: SKLabelNode?
    private var roomProgressLabel: SKLabelNode?
    private var minimap: DungeonMinimapNode?

    init(scene: GameScene, hudRoot: SKNode, viewportSize: CGSize) {
        self.scene = scene
        self.hudRoot = hudRoot
        self.viewportSize = viewportSize

        setupRoomProgressLabel()
        setupHPLabel()
        setupMinimap()
        setupJoystick()
    }

    // MARK: - Setup
    private func setupRoomProgressLabel() {
        guard let hud = hudRoot else { return }
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.alpha = 0.85
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: -viewportSize.width / 2 + 16, y: viewportSize.height / 2 - 12)
        label.zPosition = 20
        label.fontColor = .white
        hud.addChild(label)
        roomProgressLabel = label
    }

    private func setupHPLabel() {
        guard let hud = hudRoot else { return }
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.alpha = 0.85
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: -viewportSize.width / 2 + 16, y: viewportSize.height / 2 - 32)
        label.zPosition = 20
        label.fontColor = .white
        hud.addChild(label)
        hpLabel = label
    }

    private func setupMinimap() {
        guard let hud = hudRoot else { return }
        let side = min(140, max(96, viewportSize.width * 0.2))
        let panel = CGSize(width: side, height: side)
        let map = DungeonMinimapNode(mapPixelSize: panel)
        map.position = CGPoint(
            x: viewportSize.width / 2 - 12 - panel.width,
            y: viewportSize.height / 2 - 12 - panel.height
        )
        hud.addChild(map)
        minimap = map
    }

    private func setupJoystick() {
        guard let hud = hudRoot else { return }
        let j = JoystickNode()
        j.zPosition = 10
        hud.addChild(j)
        joystick = j
    }

    // MARK: - API
    func updateHP(from gameState: GameState) {
        let hearts = String(repeating: "❤️", count: max(0, gameState.hp))
        let emptyHearts = String(repeating: "🖤", count: max(0, gameState.maxHp - gameState.hp))
        hpLabel?.text = "HP: \(hearts)\(emptyHearts)"
    }

    func updateRoomProgress(floor: Int, zone: DungeonZone, clearedCount: Int, required: Int, clearedSet: Set<String>, bossSpawned: Bool, bossCleared: Bool) {
        var suffix = zone.displayTitle
        if zone.kind == .combat {
            suffix += clearedSet.contains(zone.id) ? " · Limpa" : " · Combate"
        } else if zone.kind == .boss {
            suffix += bossSpawned ? (bossCleared ? " · Aberta" : " · Bloqueada") : " · Bloqueada"
        }
        roomProgressLabel?.text = "Andar \(floor)  \(suffix)  (\(clearedCount)/\(required))"
    }

    func rebuildMinimap(for floor: Int) {
        minimap?.rebuild(for: floor)
    }

    func setClearedRooms(_ ids: Set<String>) {
        minimap?.setClearedRooms(ids)
    }

    func setHighlightedRoom(id: String) {
        minimap?.setHighlightedRoom(id: id)
    }
}
