//
//  DungeonRenderer.swift
//  GeoShot
//

import SpriteKit

final class DungeonRenderer {
    private weak var mapRoot: SKNode?

    init(mapRoot: SKNode) {
        self.mapRoot = mapRoot
    }

    /// Build geometry and doors for the given floor description.
    /// Returns a map of passage id -> DungeonDoorNode
    func build(zonesById: [String: DungeonZone], passages: [DungeonPassage], worldBounds: CGRect) -> [String: DungeonDoorNode] {
        guard let mapRoot = mapRoot else { return [:] }

        // Outer background
        let outer = SKShapeNode(rect: worldBounds)
        outer.fillColor = DungeonMapPalette.worldBackground
        outer.strokeColor = .clear
        outer.zPosition = -3
        mapRoot.addChild(outer)

        var doorNodes: [String: DungeonDoorNode] = [:]

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
            // floor
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

            // borders
            let borderPath = CGMutablePath()
            let rect = zone.floorRect

            if zone.kind == .corridor {
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
                    if pRect.minY - tolerance <= minY && pRect.maxY + tolerance >= minY {
                        bottomGaps.append((pRect.minX, pRect.maxX))
                    }
                    if pRect.minY - tolerance <= maxY && pRect.maxY + tolerance >= maxY {
                        topGaps.append((pRect.minX, pRect.maxX))
                    }
                    if pRect.minX - tolerance <= minX && pRect.maxX + tolerance >= minX {
                        leftGaps.append((pRect.minY, pRect.maxY))
                    }
                    if pRect.minX - tolerance <= maxX && pRect.maxX + tolerance >= maxX {
                        rightGaps.append((pRect.minY, pRect.maxY))
                    }
                }

                for (x1, x2) in DungeonGeometry.getSegments(start: minX, end: maxX, gaps: bottomGaps) {
                    borderPath.move(to: CGPoint(x: x1, y: minY))
                    borderPath.addLine(to: CGPoint(x: x2, y: minY))
                    addWallBody(from: CGPoint(x: x1, y: minY), to: CGPoint(x: x2, y: minY))
                }
                for (x1, x2) in DungeonGeometry.getSegments(start: minX, end: maxX, gaps: topGaps) {
                    borderPath.move(to: CGPoint(x: x1, y: maxY))
                    borderPath.addLine(to: CGPoint(x: x2, y: maxY))
                    addWallBody(from: CGPoint(x: x1, y: maxY), to: CGPoint(x: x2, y: maxY))
                }
                for (y1, y2) in DungeonGeometry.getSegments(start: minY, end: maxY, gaps: leftGaps) {
                    borderPath.move(to: CGPoint(x: minX, y: y1))
                    borderPath.addLine(to: CGPoint(x: minX, y: y2))
                    addWallBody(from: CGPoint(x: minX, y: y1), to: CGPoint(x: minX, y: y2))
                }
                for (y1, y2) in DungeonGeometry.getSegments(start: minY, end: maxY, gaps: rightGaps) {
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

        // Doors
        for passage in passages {
            let door = DungeonDoorNode(passage: passage, zonesById: zonesById)
            mapRoot.addChild(door)
            doorNodes[passage.id] = door
        }

        return doorNodes
    }
}
