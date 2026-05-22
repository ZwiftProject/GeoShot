//
//  DungeonMapPalette.swift
//  GeoShot
//
// Cores do mapa: fundo do jogo, salas (cinzento quente um pouco mais claro), bordas claras.
//

import SpriteKit

enum DungeonMapPalette {
    /// Fundo global da cena (quase preto, ligeiramente quente).
    static let worldBackground = SKColor(red: 0.022, green: 0.02, blue: 0.018, alpha: 1)
    /// Preenchimento das salas / selagem: um pouco mais claro que o fundo, tom quente.
    static let roomFill = SKColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1)
    static let startRoomFill = SKColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1)
    static let corridorFill = SKColor(red: 0.08, green: 0.075, blue: 0.07, alpha: 1)
    static let bossRoomFill = SKColor(red: 0.13, green: 0.11, blue: 0.10, alpha: 1)
    /// Borda visível das salas (cinzento claro).
    static let roomStroke = SKColor(red: 0.62, green: 0.61, blue: 0.58, alpha: 1)
    static let roomStrokeWidth: CGFloat = 3.5
}
