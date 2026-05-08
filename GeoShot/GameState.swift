//
//  GameState.swift
//  GeoShot
//

import Foundation

struct GameState {
    var hp: Int = 6
    var maxHp: Int = 6
    var score: Int = 0
    var isAlive: Bool { hp > 0 }
}
