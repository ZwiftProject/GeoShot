//
//  DungeonMinimapNode.swift
//  GeoShot
//
// Minimapa do andar atual (salas + ligações; corredores omitidos).
//

import SpriteKit

final class DungeonMinimapNode: SKNode {

    private let mapPixelSize: CGSize
    private var roomShapes: [String: SKShapeNode] = [:]
    private var highlightNode: SKShapeNode?
    private var clearedRoomIds: Set<String> = []
    private var currentFloor: Int = 1

    init(mapPixelSize: CGSize = CGSize(width: 132, height: 132)) {
        self.mapPixelSize = mapPixelSize
        super.init()
        self.zPosition = 19
        self.name = "dungeonMinimap"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func rebuild(for floor: Int) {
        removeAllChildren()
        roomShapes.removeAll()
        highlightNode = nil
        clearedRoomIds.removeAll()
        currentFloor = floor

        let worldBounds = DungeonFloorPlan.worldBounds(for: floor)
        let allById = DungeonFloorPlan.zonesById(for: floor)
        let roomZones = DungeonFloorPlan.minimapZones(for: floor)

        var drawn: Set<String> = []
        for passage in DungeonFloorPlan.passages(for: floor) {
            guard let za = allById[passage.zoneA], let zb = allById[passage.zoneB] else { continue }
            let key = [passage.zoneA, passage.zoneB].sorted().joined(separator: "|")
            guard !drawn.contains(key) else { continue }
            drawn.insert(key)

            let a = centerOfRect(za.floorRect, in: worldBounds)
            let b = centerOfRect(zb.floorRect, in: worldBounds)
            let path = CGMutablePath()
            path.move(to: a)
            path.addLine(to: b)
            let line = SKShapeNode(path: path)
            line.strokeColor = SKColor(white: 0.42, alpha: 0.9)
            line.lineWidth = 2.5
            line.zPosition = 0
            addChild(line)
        }

        for zone in roomZones {
            let rect = mapRect(zone.normalizedMinimapFrame(in: worldBounds))
            let shape = SKShapeNode(rect: rect)
            shape.lineWidth = zone.kind == .boss ? 2.5 : 1.5
            shape.zPosition = 1
            shape.name = "minimap_\(zone.id)"

            switch zone.kind {
            case .boss:
                shape.fillColor = SKColor(red: 0.22, green: 0.1, blue: 0.1, alpha: 0.95)
                shape.strokeColor = SKColor(red: 0.75, green: 0.38, blue: 0.28, alpha: 1)
            case .start:
                shape.fillColor = SKColor(red: 0.1, green: 0.095, blue: 0.088, alpha: 0.95)
                shape.strokeColor = SKColor(red: 0.55, green: 0.72, blue: 0.95, alpha: 0.95)
            case .combat:
                shape.fillColor = SKColor(red: 0.1, green: 0.092, blue: 0.085, alpha: 0.92)
                shape.strokeColor = SKColor(red: 0.58, green: 0.57, blue: 0.54, alpha: 0.95)
            case .corridor:
                break
            }

            addChild(shape)
            roomShapes[zone.id] = shape
        }
    }

    private func centerOfRect(_ rect: CGRect, in worldBounds: CGRect) -> CGPoint {
        let n = CGRect(
            x: (rect.midX - worldBounds.minX) / worldBounds.width,
            y: (rect.midY - worldBounds.minY) / worldBounds.height,
            width: 0,
            height: 0
        )
        return CGPoint(x: n.midX * mapPixelSize.width, y: n.midY * mapPixelSize.height)
    }

    private func mapRect(_ normalized: CGRect) -> CGRect {
        CGRect(
            x: normalized.minX * mapPixelSize.width,
            y: normalized.minY * mapPixelSize.height,
            width: normalized.width * mapPixelSize.width,
            height: normalized.height * mapPixelSize.height
        )
    }

    func setClearedRooms(_ ids: Set<String>) {
        clearedRoomIds = ids
        for (id, shape) in roomShapes {
            shape.alpha = ids.contains(id) && id != "bossHub" ? 0.45 : 1
        }
    }

    func setHighlightedRoom(id: String?) {
        highlightNode?.removeFromParent()
        highlightNode = nil
        guard let id = id, let base = roomShapes[id], let pathCopy = base.path else { return }
        let glow = SKShapeNode(path: pathCopy)
        glow.strokeColor = .yellow
        glow.fillColor = .clear
        glow.lineWidth = base.lineWidth + 3
        glow.zPosition = 2
        glow.position = base.position
        addChild(glow)
        highlightNode = glow
    }
}
