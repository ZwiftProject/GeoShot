//
//  GameViewController.swift
//  GeoShot
//
//  Created by Joao Ribeiro on 22/04/2026.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    private var scenePresented = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Present scene once when the view has its final size
        guard !scenePresented, let skView = self.view as? SKView else { return }

        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0, y: 0)

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        scenePresented = true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
