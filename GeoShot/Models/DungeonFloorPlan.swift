//
//  DungeonFloorPlan.swift
//  GeoShot
//
// Mapa contínuo por andar: salas + corredores em coordenadas de mundo,
// passagens com portas, salas de combate obrigatórias antes do boss.
//

import CoreGraphics
import Foundation

enum ZoneKind: Equatable {
    case start
    case corridor
    case combat
    case boss
}

struct DungeonZone: Equatable {
    let id: String
    let displayTitle: String
    let kind: ZoneKind
    let floorRect: CGRect
    let wallInset: CGFloat

    var walkBounds: CGRect {
        floorRect.insetBy(dx: wallInset, dy: wallInset)
    }

    func normalizedMinimapFrame(in worldBounds: CGRect) -> CGRect {
        guard worldBounds.width > 0, worldBounds.height > 0 else { return .zero }
        return CGRect(
            x: (floorRect.minX - worldBounds.minX) / worldBounds.width,
            y: (floorRect.minY - worldBounds.minY) / worldBounds.height,
            width: floorRect.width / worldBounds.width,
            height: floorRect.height / worldBounds.height
        )
    }
}

/// Liga duas zonas; o retângulo é bloqueado visualmente (borda da sala) quando a entrada fecha.
struct DungeonPassage: Equatable {
    let id: String
    let zoneA: String
    let zoneB: String
    let rect: CGRect

    func connects(_ zoneId: String) -> Bool {
        zoneA == zoneId || zoneB == zoneId
    }

    func otherZone(from zoneId: String) -> String? {
        if zoneA == zoneId { return zoneB }
        if zoneB == zoneId { return zoneA }
        return nil
    }
}

enum DungeonFloorPlan {

    /// Escala global do layout (salas e corredores maiores).
    private static let layoutScale: CGFloat = 2.2

    private static func sc(_ r: CGRect) -> CGRect {
        CGRect(
            x: (r.origin.x * layoutScale).rounded(),
            y: (r.origin.y * layoutScale).rounded(),
            width: (r.size.width * layoutScale).rounded(),
            height: (r.size.height * layoutScale).rounded()
        )
    }

    private static func scaledZone(_ z: DungeonZone) -> DungeonZone {
        DungeonZone(
            id: z.id,
            displayTitle: z.displayTitle,
            kind: z.kind,
            floorRect: sc(z.floorRect),
            wallInset: z.kind == .corridor ? 12 : 22
        )
    }

    private static func scaledPassage(_ p: DungeonPassage) -> DungeonPassage {
        DungeonPassage(id: p.id, zoneA: p.zoneA, zoneB: p.zoneB, rect: sc(p.rect))
    }

    // MARK: - Andar 1 (coordenadas base; aplicado layoutScale)

    private static let rawFloor1Zones: [DungeonZone] = [
        DungeonZone(id: "start", displayTitle: "Entrada", kind: .start,
                    floorRect: CGRect(x: 80, y: 1300, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_start_midWest", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 212, y: 1020, width: 56, height: 280), wallInset: 12),
        DungeonZone(id: "midWest", displayTitle: "Sala Oeste", kind: .combat,
                    floorRect: CGRect(x: 80, y: 800, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_midWest_centerHub", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 400, y: 882, width: 200, height: 56), wallInset: 12),
        DungeonZone(id: "centerHub", displayTitle: "Sala Central", kind: .combat,
                    floorRect: CGRect(x: 600, y: 800, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_centerHub_north", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 732, y: 1020, width: 56, height: 280), wallInset: 12),
        DungeonZone(id: "north", displayTitle: "Sala Norte", kind: .combat,
                    floorRect: CGRect(x: 600, y: 1300, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_centerHub_bossHub", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 920, y: 882, width: 200, height: 56), wallInset: 12),
        DungeonZone(id: "bossHub", displayTitle: "Salão do Chefe", kind: .boss,
                    floorRect: CGRect(x: 1120, y: 730, width: 360, height: 360), wallInset: 32)
    ]

    private static let rawFloor1Passages: [DungeonPassage] = [
        DungeonPassage(id: "p_start_corr", zoneA: "start", zoneB: "corr_start_midWest",
                       rect: CGRect(x: 212, y: 1272, width: 56, height: 56)),
        DungeonPassage(id: "p_corr_midWest", zoneA: "corr_start_midWest", zoneB: "midWest",
                       rect: CGRect(x: 212, y: 992, width: 56, height: 56)),
        DungeonPassage(id: "p_midWest_centerHub", zoneA: "midWest", zoneB: "corr_midWest_centerHub",
                       rect: CGRect(x: 372, y: 882, width: 56, height: 56)),
        DungeonPassage(id: "p_centerHub_left", zoneA: "corr_midWest_centerHub", zoneB: "centerHub",
                       rect: CGRect(x: 572, y: 882, width: 56, height: 56)),
        DungeonPassage(id: "p_centerHub_top", zoneA: "centerHub", zoneB: "corr_centerHub_north",
                       rect: CGRect(x: 732, y: 992, width: 56, height: 56)),
        DungeonPassage(id: "p_north_corr", zoneA: "corr_centerHub_north", zoneB: "north",
                       rect: CGRect(x: 732, y: 1272, width: 56, height: 56)),
        DungeonPassage(id: "p_centerHub_bossCorr", zoneA: "centerHub", zoneB: "corr_centerHub_bossHub",
                       rect: CGRect(x: 892, y: 882, width: 56, height: 56)),
        DungeonPassage(id: "p_bossCorr_bossHub", zoneA: "corr_centerHub_bossHub", zoneB: "bossHub",
                       rect: CGRect(x: 1092, y: 882, width: 56, height: 56))
    ]

    private static let floor1Zones: [DungeonZone] = rawFloor1Zones.map(scaledZone)
    private static let floor1Passages: [DungeonPassage] = rawFloor1Passages.map(scaledPassage)

    private static let floor1RequiredCombat: Set<String> = ["midWest", "centerHub", "north"]

    // MARK: - Andar 2

    private static let rawFloor2Zones: [DungeonZone] = [
        DungeonZone(id: "start", displayTitle: "Entrada", kind: .start,
                    floorRect: CGRect(x: 80, y: 1300, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_start_midWest", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 212, y: 1020, width: 56, height: 280), wallInset: 12),
        DungeonZone(id: "midWest", displayTitle: "Sala Oeste", kind: .combat,
                    floorRect: CGRect(x: 80, y: 800, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_midWest_southWest", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 212, y: 520, width: 56, height: 280), wallInset: 12),
        DungeonZone(id: "southWest", displayTitle: "Sala Sudoeste", kind: .combat,
                    floorRect: CGRect(x: 80, y: 300, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_southWest_south", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 400, y: 382, width: 200, height: 56), wallInset: 12),
        DungeonZone(id: "south", displayTitle: "Sala Sul", kind: .combat,
                    floorRect: CGRect(x: 600, y: 300, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_midWest_centerHub", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 400, y: 882, width: 200, height: 56), wallInset: 12),
        DungeonZone(id: "corr_south_centerHub", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 732, y: 520, width: 56, height: 280), wallInset: 12),
        DungeonZone(id: "centerHub", displayTitle: "Sala Central", kind: .combat,
                    floorRect: CGRect(x: 600, y: 800, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_centerHub_north", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 732, y: 1020, width: 56, height: 280), wallInset: 12),
        DungeonZone(id: "north", displayTitle: "Sala Norte", kind: .combat,
                    floorRect: CGRect(x: 600, y: 1300, width: 320, height: 220), wallInset: 28),
        DungeonZone(id: "corr_centerHub_bossHub", displayTitle: "Corredor", kind: .corridor,
                    floorRect: CGRect(x: 920, y: 882, width: 200, height: 56), wallInset: 12),
        DungeonZone(id: "bossHub", displayTitle: "Salão do Chefe", kind: .boss,
                    floorRect: CGRect(x: 1120, y: 730, width: 360, height: 360), wallInset: 32)
    ]

    private static let rawFloor2Passages: [DungeonPassage] = [
        DungeonPassage(id: "p_start_corr", zoneA: "start", zoneB: "corr_start_midWest",
                       rect: CGRect(x: 212, y: 1272, width: 56, height: 56)),
        DungeonPassage(id: "p_corr_midWest", zoneA: "corr_start_midWest", zoneB: "midWest",
                       rect: CGRect(x: 212, y: 992, width: 56, height: 56)),
        DungeonPassage(id: "p_midWest_corr2", zoneA: "midWest", zoneB: "corr_midWest_southWest",
                       rect: CGRect(x: 212, y: 772, width: 56, height: 56)),
        DungeonPassage(id: "p_corr2_southWest", zoneA: "corr_midWest_southWest", zoneB: "southWest",
                       rect: CGRect(x: 212, y: 492, width: 56, height: 56)),
        DungeonPassage(id: "p_southWest_corr3", zoneA: "southWest", zoneB: "corr_southWest_south",
                       rect: CGRect(x: 372, y: 382, width: 56, height: 56)),
        DungeonPassage(id: "p_corr3_south", zoneA: "corr_southWest_south", zoneB: "south",
                       rect: CGRect(x: 572, y: 382, width: 56, height: 56)),
        DungeonPassage(id: "p_midWest_centerHub", zoneA: "midWest", zoneB: "corr_midWest_centerHub",
                       rect: CGRect(x: 372, y: 882, width: 56, height: 56)),
        DungeonPassage(id: "p_centerHub_left", zoneA: "corr_midWest_centerHub", zoneB: "centerHub",
                       rect: CGRect(x: 572, y: 882, width: 56, height: 56)),
        DungeonPassage(id: "p_south_centerHub", zoneA: "south", zoneB: "corr_south_centerHub",
                       rect: CGRect(x: 732, y: 492, width: 56, height: 56)),
        DungeonPassage(id: "p_centerHub_bottom", zoneA: "corr_south_centerHub", zoneB: "centerHub",
                       rect: CGRect(x: 732, y: 772, width: 56, height: 56)),
        DungeonPassage(id: "p_centerHub_top", zoneA: "centerHub", zoneB: "corr_centerHub_north",
                       rect: CGRect(x: 732, y: 992, width: 56, height: 56)),
        DungeonPassage(id: "p_north_corr", zoneA: "corr_centerHub_north", zoneB: "north",
                       rect: CGRect(x: 732, y: 1272, width: 56, height: 56)),
        DungeonPassage(id: "p_centerHub_bossCorr", zoneA: "centerHub", zoneB: "corr_centerHub_bossHub",
                       rect: CGRect(x: 892, y: 882, width: 56, height: 56)),
        DungeonPassage(id: "p_bossCorr_bossHub", zoneA: "corr_centerHub_bossHub", zoneB: "bossHub",
                       rect: CGRect(x: 1092, y: 882, width: 56, height: 56))
    ]

    private static let floor2Zones: [DungeonZone] = rawFloor2Zones.map(scaledZone)
    private static let floor2Passages: [DungeonPassage] = rawFloor2Passages.map(scaledPassage)

    private static let floor2RequiredCombat: Set<String> = ["midWest", "southWest", "south", "centerHub", "north"]

    // MARK: - API

    static func zones(for floor: Int) -> [DungeonZone] {
        floor == 1 ? floor1Zones : floor2Zones
    }

    static func zonesById(for floor: Int) -> [String: DungeonZone] {
        Dictionary(uniqueKeysWithValues: zones(for: floor).map { ($0.id, $0) })
    }

    static func passages(for floor: Int) -> [DungeonPassage] {
        floor == 1 ? floor1Passages : floor2Passages
    }

    static func requiredCombatZoneIds(for floor: Int) -> Set<String> {
        floor == 1 ? floor1RequiredCombat : floor2RequiredCombat
    }

    static func worldBounds(for floor: Int) -> CGRect {
        let all = zones(for: floor).map(\.floorRect)
        guard let first = all.first else { return .zero }
        let pad = (48 * layoutScale).rounded()
        return all.dropFirst().reduce(first) { $0.union($1) }.insetBy(dx: -pad, dy: -pad)
    }

    static func zoneId(at point: CGPoint, floor: Int) -> String? {
        let hits = zones(for: floor).filter { $0.floorRect.contains(point) }
        return hits.min(by: { $0.floorRect.width * $0.floorRect.height < $1.floorRect.width * $1.floorRect.height })?.id
    }

    static func passage(between zoneA: String, and zoneB: String, floor: Int) -> DungeonPassage? {
        passages(for: floor).first { p in
            (p.zoneA == zoneA && p.zoneB == zoneB) || (p.zoneA == zoneB && p.zoneB == zoneA)
        }
    }

    static func passages(forZone zoneId: String, floor: Int) -> [DungeonPassage] {
        passages(for: floor).filter { $0.connects(zoneId) }
    }

    static func involvesBoss(_ passage: DungeonPassage) -> Bool {
        passage.zoneA == "bossHub" || passage.zoneB == "bossHub"
    }

    static func floorNumber(containing zoneId: String) -> Int {
        if floor1Zones.contains(where: { $0.id == zoneId }) { return 1 }
        return 2
    }

    /// Zonas visíveis no minimapa (sem corredores estreitos).
    static func minimapZones(for floor: Int) -> [DungeonZone] {
        zones(for: floor).filter { $0.kind != .corridor }
    }
}
