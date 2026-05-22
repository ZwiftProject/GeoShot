//
//  GameState.swift
//  GeoShot
//

import Foundation

final class GameState {
    var hp: Int = 6
    var maxHp: Int = 6
    var score: Int = 0
    var damageDealt: Int = 0
    var elapsedTime: TimeInterval = 0

    var isAlive: Bool { hp > 0 }

    init(hp: Int = 6, maxHp: Int = 6, score: Int = 0, damageDealt: Int = 0, elapsedTime: TimeInterval = 0) {
        self.hp = hp
        self.maxHp = maxHp
        self.score = score
        self.damageDealt = damageDealt
        self.elapsedTime = elapsedTime
    }

    func takeDamage(_ amount: Int = 1) {
        hp = max(0, hp - amount)
    }

    func heal(_ amount: Int = 1) {
        hp = min(maxHp, hp + amount)
    }

    func addScore(_ points: Int) {
        score += points
    }

    func addDamage(_ amount: Int = 1) {
        damageDealt += amount
    }

    func reset() {
        hp = maxHp
        score = 0
        damageDealt = 0
        elapsedTime = 0
    }
}
