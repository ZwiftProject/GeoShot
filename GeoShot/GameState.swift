//
//  GameState.swift
//  GeoShot
//

import Foundation
import SpriteKit

enum UpgradeType: String, CaseIterable {
    case life = "HP"
    case extraBullet = "BL"
    case damage = "DMG"
    case speed = "SPD"
    case fireRate = "FR"
    case piercing = "PRC"
    case regen = "REG"

    var name: String {
        switch self {
        case .life: return "+Vida"
        case .extraBullet: return "+Balas"
        case .damage: return "+Dano"
        case .speed: return "+Velocidade"
        case .fireRate: return "+Vel. Disparo"
        case .piercing: return "+Perfurante"
        case .regen: return "+Regeneração"
        }
    }

    var shortName: String {
        return self.rawValue
    }

    var color: SKColor {
        switch self {
        case .life: return SKColor(red: 0.1, green: 0.8, blue: 0.3, alpha: 1.0)
        case .extraBullet: return SKColor(red: 0.0, green: 0.8, blue: 0.9, alpha: 1.0)
        case .damage: return SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        case .speed: return SKColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 1.0)
        case .fireRate: return SKColor(red: 0.9, green: 0.8, blue: 0.1, alpha: 1.0)
        case .piercing: return SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)
        case .regen: return SKColor(red: 0.9, green: 0.3, blue: 0.6, alpha: 1.0)
        }
    }
}

final class GameState {
    var hp: Int = 6
    var maxHp: Int = 6
    var score: Int = 0
    var damageDealt: Int = 0
    var elapsedTime: TimeInterval = 0
    var upgrades: [UpgradeType] = []

    var isAlive: Bool { hp > 0 }

    init(hp: Int = 6, maxHp: Int = 6, score: Int = 0, damageDealt: Int = 0, elapsedTime: TimeInterval = 0, upgrades: [UpgradeType] = []) {
        self.hp = hp
        self.maxHp = maxHp
        self.score = score
        self.damageDealt = damageDealt
        self.elapsedTime = elapsedTime
        self.upgrades = upgrades
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

    func addUpgrade(_ upgrade: UpgradeType) {
        upgrades.append(upgrade)
        switch upgrade {
        case .life:
            maxHp += 2
            heal(2)
        default:
            break
        }
    }

    func reset() {
        maxHp = 6
        hp = 6
        score = 0
        damageDealt = 0
        elapsedTime = 0
        upgrades = []
    }
}
