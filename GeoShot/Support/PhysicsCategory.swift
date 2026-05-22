import Foundation

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let enemy: UInt32  = 1 << 1
    static let bullet: UInt32 = 1 << 2
    static let wall: UInt32   = 1 << 3
}
