//
//  DungeonMap.swift
//  GeoShot
//
// Estrutura da run: Andar 1 (3 combates + miniboss Plus), Andar 2 (3 combates + boss Pentagon).
// Parâmetros de dificuldade escalam por andar (quantidade, velocidade; dano reservado para contacto futuro).
//

import CoreGraphics
import Foundation

/// Tipo de conteúdo de uma sala na sequência fixa da dungeon.
enum DungeonRoomKind: Equatable {
    case combat
    case minibossPlus
    case bossPentagon
}

/// Uma entrada na sequência linear da run (corredor → sala → …).
struct DungeonRoomStep: Equatable {
    let floor: Int
    /// 1-based índice da sala dentro do andar (1…4).
    let roomNumberOnFloor: Int
    let kind: DungeonRoomKind
    /// Identificador da sala no grafo espacial (`DungeonLayoutMap`).
    let layoutRoomId: String

    var isLastStep: Bool {
        self == DungeonMap.runSequence.last
    }
}

/// Dificuldade por andar: mais inimigos, maior velocidade (e campo para dano de contacto quando existir).
struct FloorDifficulty: Equatable {
    let combatTriangleCount: Int
    let triangleMoveSpeed: CGFloat
    let combatSquaredCount: Int
    let squaredMoveSpeed: CGFloat
    /// Dano por contacto com inimigo (triângulo / quadrado); usado quando a física jogador–inimigo estiver ativa.
    let enemyContactDamage: Int

    static func forFloor(_ floor: Int) -> FloorDifficulty {
        switch floor {
        case 1:
            return FloorDifficulty(
                combatTriangleCount: 5,
                triangleMoveSpeed: 10,
                combatSquaredCount: 0,
                squaredMoveSpeed: 90,
                enemyContactDamage: 1
            )
        default:
            // Andar 2 e superiores: mais inimigos, mais rápidos, mais dano.
            return FloorDifficulty(
                combatTriangleCount: 7,
                triangleMoveSpeed: 15,
                combatSquaredCount: 1,
                squaredMoveSpeed: 115,
                enemyContactDamage: 2
            )
        }
    }
}

enum DungeonMap {
    /// Sequência completa: 3 combates + Plus no andar 1; 3 combates + Pentagon no andar 2.
    static let runSequence: [DungeonRoomStep] = buildRunSequence()

    private static func buildRunSequence() -> [DungeonRoomStep] {
        var steps: [DungeonRoomStep] = []

        for (index, roomId) in DungeonLayoutMap.floor1VisitOrder.enumerated() {
            let roomNum = index + 1
            let kind: DungeonRoomKind = roomId == "bossHub" ? .minibossPlus : .combat
            steps.append(DungeonRoomStep(floor: 1, roomNumberOnFloor: roomNum, kind: kind, layoutRoomId: roomId))
        }

        for (index, roomId) in DungeonLayoutMap.floor2VisitOrder.enumerated() {
            let roomNum = index + 1
            let kind: DungeonRoomKind = roomId == "bossHub" ? .bossPentagon : .combat
            steps.append(DungeonRoomStep(floor: 2, roomNumberOnFloor: roomNum, kind: kind, layoutRoomId: roomId))
        }

        return steps
    }

    static func difficulty(forFloor floor: Int) -> FloorDifficulty {
        FloorDifficulty.forFloor(floor)
    }
}
