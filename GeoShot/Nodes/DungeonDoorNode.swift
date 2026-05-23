//
//  DungeonDoorNode.swift
//  GeoShot
//
// Selagem da entrada: invisível quando aberta; ao fechar, desenha apenas a continuação
// da borda (borda cinzenta clara) fechando a zona da entrada, sem porta física visível.
//

import SpriteKit

final class DungeonDoorNode: SKShapeNode {

    let passageId: String
    private(set) var isOpen: Bool = true

    init(passage: DungeonPassage, zonesById: [String: DungeonZone]) {
        self.passageId = passage.id
        super.init()
        self.zPosition = 4
        self.name = "entranceSeal_\(passage.id)"

        let path = CGMutablePath()
        
        // Determinar quais zonas conectadas são salas (não corredores) e interceptam a passagem
        let connectedZones = [zonesById[passage.zoneA], zonesById[passage.zoneB]].compactMap { $0 }
        for zone in connectedZones where zone.kind != .corridor {
            let rect = zone.floorRect
            let minX = rect.minX
            let maxX = rect.maxX
            let minY = rect.minY
            let maxY = rect.maxY
            
            let pRect = passage.rect
            let tolerance: CGFloat = 2.0
            
            // Borda inferior: y = minY
            if pRect.minY - tolerance <= minY && pRect.maxY + tolerance >= minY {
                let xStart = max(pRect.minX, minX)
                let xEnd = min(pRect.maxX, maxX)
                path.move(to: CGPoint(x: xStart, y: minY))
                path.addLine(to: CGPoint(x: xEnd, y: minY))
            }
            // Borda superior: y = maxY
            if pRect.minY - tolerance <= maxY && pRect.maxY + tolerance >= maxY {
                let xStart = max(pRect.minX, minX)
                let xEnd = min(pRect.maxX, maxX)
                path.move(to: CGPoint(x: xStart, y: maxY))
                path.addLine(to: CGPoint(x: xEnd, y: maxY))
            }
            // Borda esquerda: x = minX
            if pRect.minX - tolerance <= minX && pRect.maxX + tolerance >= minX {
                let yStart = max(pRect.minY, minY)
                let yEnd = min(pRect.maxY, maxY)
                path.move(to: CGPoint(x: minX, y: yStart))
                path.addLine(to: CGPoint(x: minX, y: yEnd))
            }
            // Borda direita: x = maxX
            if pRect.minX - tolerance <= maxX && pRect.maxX + tolerance >= maxX {
                let yStart = max(pRect.minY, minY)
                let yEnd = min(pRect.maxY, maxY)
                path.move(to: CGPoint(x: maxX, y: yStart))
                path.addLine(to: CGPoint(x: maxX, y: yEnd))
            }
        }
        
        self.path = path
        setOpen(true, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setOpen(_ open: Bool, animated: Bool = true) {
        self.isOpen = open
        if open {
            removeAllActions()
            isHidden = true
            alpha = 1
            self.physicsBody = nil
        } else {
            isHidden = false
            fillColor = .clear // Sem porta física sólida
            strokeColor = DungeonMapPalette.roomStroke
            lineWidth = DungeonMapPalette.roomStrokeWidth
            if let path = self.path, !path.isEmpty {
                let bounds = path.boundingBoxOfPath
                self.physicsBody = SKPhysicsBody(rectangleOf: bounds.size, center: CGPoint(x: bounds.midX, y: bounds.midY))
                self.physicsBody?.isDynamic = false
                self.physicsBody?.categoryBitMask = PhysicsCategory.wall
                self.physicsBody?.contactTestBitMask = PhysicsCategory.bullet
                self.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
            }
            if animated {
                alpha = 0
                run(.fadeIn(withDuration: 0.12))
            } else {
                alpha = 1
            }
        }
    }
}
