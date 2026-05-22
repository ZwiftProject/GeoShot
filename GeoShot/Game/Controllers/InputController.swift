import SpriteKit

final class InputController {
    private weak var scene: GameScene?

    init(scene: GameScene) {
        self.scene = scene
    }

    func handleTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let scene = scene else { return }

        for touch in touches {
            let location = touch.location(in: scene.gameCamera)
            if scene.joystickTouch == nil && scene.isInJoystickArea(location) {
                scene.joystickTouch = touch
                scene.joystick.appear(at: location)
            } else if scene.fireTouch == nil && scene.isInFireArea(location) {
                scene.fireTouch = touch
            }
        }
    }

    func handleTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let scene = scene, let joystickTouch = scene.joystickTouch, touches.contains(joystickTouch) else { return }
        scene.joystick.update(to: joystickTouch.location(in: scene.gameCamera))
    }

    func handleTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let scene = scene else { return }

        for touch in touches {
            if touch == scene.joystickTouch {
                scene.joystickTouch = nil
                scene.joystick.disappear()
            }
            if touch == scene.fireTouch {
                scene.fireTouch = nil
            }
        }
    }
}
