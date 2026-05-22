import SpriteKit

final class CameraController {
    private weak var scene: GameScene?

    init(scene: GameScene) {
        self.scene = scene
    }

    func update(deltaTime: TimeInterval) {
        guard let scene = scene else { return }

        let target = clampedCameraPosition(focus: scene.cameraFocusPosition())
        guard deltaTime > 0 else {
            scene.setCameraPosition(target)
            return
        }

        let current = scene.cameraNode().position
        let t = min(1, scene.cameraFollowSmoothingValue() * CGFloat(deltaTime))
        scene.setCameraPosition(CGPoint(
            x: current.x + (target.x - current.x) * t,
            y: current.y + (target.y - current.y) * t
        ))
    }

    func snapToPlayer() {
        guard let scene = scene else { return }
        scene.setCameraPosition(clampedCameraPosition(focus: scene.cameraFocusPosition()))
    }

    private func clampedCameraPosition(focus: CGPoint) -> CGPoint {
        guard let scene = scene else { return focus }

        let viewportSize = scene.cameraViewportSize()
        let worldBounds = scene.cameraWorldBounds()

        let halfW = viewportSize.width / 2
        let halfH = viewportSize.height / 2
        let minX = worldBounds.minX + halfW
        let maxX = worldBounds.maxX - halfW
        let minY = worldBounds.minY + halfH
        let maxY = worldBounds.maxY - halfH

        var x = focus.x
        var y = focus.y
        if minX > maxX {
            x = worldBounds.midX
        } else {
            x = min(max(x, minX), maxX)
        }

        if minY > maxY {
            y = worldBounds.midY
        } else {
            y = min(max(y, minY), maxY)
        }

        return CGPoint(x: x, y: y)
    }
}
