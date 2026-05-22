//
//  DungeonLayoutMap.swift
//  GeoShot
//
// Layout em grafo inspirado em dungeon hub-and-spoke: salas pequenas (combate),
// salão central grande (miniboss no andar 1, boss final no andar 2), portal de entrada.
// Coordenadas normalizadas (0…1), origem no canto inferior esquerdo do painel do mapa.
//

import CoreGraphics
import Foundation

enum LayoutRoomRole: Equatable {
    case portal
    case combat
    case annex
    case bossHub
}

struct DungeonLayoutRoom: Equatable {
    let id: String
    let displayTitle: String
    let role: LayoutRoomRole
    /// Retângulo em espaço 0…1 (origem inferior-esquerda do mapa).
    let normalizedFrame: CGRect
    let neighborIds: [String]

    var centerInNormalizedSpace: CGPoint {
        CGPoint(x: normalizedFrame.midX, y: normalizedFrame.midY)
    }
}

/// Grafo fixo da dungeon (uma malha para toda a run).
enum DungeonLayoutMap {

    private static let roomList: [DungeonLayoutRoom] = [
        DungeonLayoutRoom(
            id: "start",
            displayTitle: "Entrada",
            role: .portal,
            normalizedFrame: CGRect(x: 0.05, y: 0.75, width: 0.22, height: 0.18),
            neighborIds: ["midWest"]
        ),
        DungeonLayoutRoom(
            id: "midWest",
            displayTitle: "Sala Oeste",
            role: .combat,
            normalizedFrame: CGRect(x: 0.05, y: 0.45, width: 0.22, height: 0.18),
            neighborIds: ["start", "southWest", "centerHub"]
        ),
        DungeonLayoutRoom(
            id: "southWest",
            displayTitle: "Sala Sudoeste",
            role: .combat,
            normalizedFrame: CGRect(x: 0.05, y: 0.15, width: 0.22, height: 0.18),
            neighborIds: ["midWest", "south"]
        ),
        DungeonLayoutRoom(
            id: "south",
            displayTitle: "Sala Sul",
            role: .combat,
            normalizedFrame: CGRect(x: 0.39, y: 0.15, width: 0.22, height: 0.18),
            neighborIds: ["southWest", "centerHub"]
        ),
        DungeonLayoutRoom(
            id: "centerHub",
            displayTitle: "Sala Central",
            role: .combat,
            normalizedFrame: CGRect(x: 0.39, y: 0.45, width: 0.22, height: 0.18),
            neighborIds: ["midWest", "south", "north", "bossHub"]
        ),
        DungeonLayoutRoom(
            id: "north",
            displayTitle: "Sala Norte",
            role: .annex,
            normalizedFrame: CGRect(x: 0.39, y: 0.75, width: 0.22, height: 0.18),
            neighborIds: ["centerHub"]
        ),
        DungeonLayoutRoom(
            id: "bossHub",
            displayTitle: "Salão do Chefe",
            role: .bossHub,
            normalizedFrame: CGRect(x: 0.73, y: 0.42, width: 0.22, height: 0.24),
            neighborIds: ["centerHub"]
        )
    ]

    static let roomsById: [String: DungeonLayoutRoom] = {
        var dict: [String: DungeonLayoutRoom] = [:]
        for r in roomList {
            dict[r.id] = r
        }
        return dict
    }()

    /// Ordem de visita do andar 1
    static let floor1VisitOrder: [String] = ["start", "midWest", "southWest", "south", "centerHub", "north", "bossHub"]

    /// Andar 2
    static let floor2VisitOrder: [String] = ["start", "midWest", "southWest", "south", "centerHub", "north", "bossHub"]

    static func displayTitle(forRoomId id: String) -> String {
        roomsById[id]?.displayTitle ?? id
    }
}
