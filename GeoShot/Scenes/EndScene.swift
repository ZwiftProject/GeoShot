//
//  EndScene.swift
//  GeoShot
//
//  Created by Joao Ribeiro on 20/05/2026.
//

import SpriteKit

class EndScene: SKScene {
    
    private let isVictory: Bool
    private let score: Int
    private let time: TimeInterval
    private let damageDealt: Int
    
    private var leaderboardOverlay: LeaderboardOverlayNode?
    
    init(size: CGSize, isVictory: Bool, score: Int, time: TimeInterval, damageDealt: Int) {
        self.isVictory = isVictory
        self.score = score
        self.time = time
        self.damageDealt = damageDealt
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
        setupUI()
        
        if score > 0 {
            let wait = SKAction.wait(forDuration: 1.5)
            let presentAlert = SKAction.run { [weak self] in
                self?.presentNameInputAlert()
            }
            run(SKAction.sequence([wait, presentAlert]))
        }
    }
    
    private func setupUI() {
        let screenCenter = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        // 1. TITLE: VICTORY or GAME OVER
        let titleContainer = SKNode()
        let titleY = self.size.height * 0.82
        titleContainer.position = CGPoint(x: screenCenter.x, y: titleY)
        addChild(titleContainer)
        
        let titleText = isVictory ? "VICTORY" : "GAME OVER"
        let themeColor: SKColor = isVictory ? .cyan : .red
        
        // Glow Offsets
        let glowOffsets = [
            CGPoint(x: -2, y: -2), CGPoint(x: 2, y: -2),
            CGPoint(x: -2, y: 2), CGPoint(x: 2, y: 2),
            CGPoint(x: 0, y: -3), CGPoint(x: 0, y: 3),
            CGPoint(x: -3, y: 0), CGPoint(x: 3, y: 0)
        ]
        
        for offset in glowOffsets {
            let glowLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            glowLabel.text = titleText
            glowLabel.fontSize = isVictory ? 56 : 50
            glowLabel.fontColor = themeColor
            glowLabel.position = offset
            glowLabel.zPosition = 1
            glowLabel.alpha = 0.5
            titleContainer.addChild(glowLabel)
        }
        
        let mainTitle = SKLabelNode(fontNamed: "Menlo-Bold")
        mainTitle.text = titleText
        mainTitle.fontSize = isVictory ? 56 : 50
        mainTitle.fontColor = .white
        mainTitle.position = .zero
        mainTitle.zPosition = 2
        titleContainer.addChild(mainTitle)
        
        // Title Pulse Animation
        let pulseUp = SKAction.scale(to: 1.03, duration: 1.2)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.97, duration: 1.2)
        pulseDown.timingMode = .easeInEaseOut
        let pulseSeq = SKAction.sequence([pulseUp, pulseDown])
        titleContainer.run(SKAction.repeatForever(pulseSeq))
        
        // Divider line for Game Over
        if !isVictory {
            let linePath = CGMutablePath()
            linePath.move(to: CGPoint(x: -160, y: 0))
            linePath.addLine(to: CGPoint(x: 160, y: 0))
            
            let divider = SKShapeNode(path: linePath)
            divider.strokeColor = .red
            divider.lineWidth = 2.0
            divider.glowWidth = 3.0
            divider.position = CGPoint(x: screenCenter.x, y: titleY - 45)
            divider.zPosition = 3
            addChild(divider)
        }
        
        // 2. CENTER PIECE
        if isVictory {
            // Gold Medal Hexagon + Star
            let medalNode = SKNode()
            let iconY = self.size.height * 0.53
            medalNode.position = CGPoint(x: screenCenter.x, y: iconY)
            medalNode.zPosition = 5
            addChild(medalNode)
            
            // Hexagon path
            let hexPath = createHexagonPath(size: 45)
            let hexNode = SKShapeNode(path: hexPath)
            hexNode.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 1.0) // Gold
            hexNode.strokeColor = SKColor(red: 0.95, green: 0.80, blue: 0.25, alpha: 1.0)
            hexNode.lineWidth = 3.0
            hexNode.glowWidth = 1.0
            medalNode.addChild(hexNode)
            
            // Star path
            let starPath = createStarPath(points: 5, innerRadius: 10, outerRadius: 22)
            let starNode = SKShapeNode(path: starPath)
            starNode.fillColor = SKColor(red: 0.98, green: 0.92, blue: 0.50, alpha: 1.0) // Bright Gold
            starNode.strokeColor = .white
            starNode.lineWidth = 1.5
            starNode.position = CGPoint(x: 0, y: 0)
            medalNode.addChild(starNode)
            
            // Spin/scale animation
            let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 12.0)
            hexNode.run(SKAction.repeatForever(rotateAction))
            
            let pulseMedalUp = SKAction.scale(to: 1.08, duration: 1.5)
            pulseMedalUp.timingMode = .easeInEaseOut
            let pulseMedalDown = SKAction.scale(to: 0.92, duration: 1.5)
            pulseMedalDown.timingMode = .easeInEaseOut
            medalNode.run(SKAction.repeatForever(SKAction.sequence([pulseMedalUp, pulseMedalDown])))
        } else {
            // Game Over graphic placeholder (simple red triangle/dungeon icon)
            let graphicNode = SKNode()
            let iconY = self.size.height * 0.53
            graphicNode.position = CGPoint(x: screenCenter.x, y: iconY)
            graphicNode.zPosition = 5
            addChild(graphicNode)
            
            // A broken skull/cross outline in red vector style
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -25, y: -25))
            path.addLine(to: CGPoint(x: 25, y: 25))
            path.move(to: CGPoint(x: 25, y: -25))
            path.addLine(to: CGPoint(x: -25, y: 25))
            
            let crossNode = SKShapeNode(path: path)
            crossNode.strokeColor = .red
            crossNode.lineWidth = 4.0
            crossNode.glowWidth = 3.0
            graphicNode.addChild(crossNode)
            
            let pulseCrossUp = SKAction.scale(to: 1.15, duration: 0.8)
            pulseCrossUp.timingMode = .easeInEaseOut
            let pulseCrossDown = SKAction.scale(to: 0.85, duration: 0.8)
            pulseCrossDown.timingMode = .easeInEaseOut
            graphicNode.run(SKAction.repeatForever(SKAction.sequence([pulseCrossUp, pulseCrossDown])))
        }
        
        // 3. STATS LIST: SCORE, TIME, DAMAGE
        let statsContainer = SKNode()
        let statsY = self.size.height * 0.35
        statsContainer.position = CGPoint(x: screenCenter.x, y: statsY)
        statsContainer.zPosition = 8
        addChild(statsContainer)
        
        // Score Label
        let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.text = "SCORE: \(score)"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: 35)
        scoreLabel.alpha = 0 // for fade in animation
        statsContainer.addChild(scoreLabel)
        
        // Time Label
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        let timeLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timeLabel.text = "TIME: \(timeString)"
        timeLabel.fontSize = 20
        timeLabel.fontColor = .white
        timeLabel.position = CGPoint(x: 0, y: 5)
        timeLabel.alpha = 0
        statsContainer.addChild(timeLabel)
        
        // Damage Label
        let damageLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        damageLabel.text = "DAMAGE DEALT: \(damageDealt)"
        damageLabel.fontSize = 18
        damageLabel.fontColor = .white
        damageLabel.position = CGPoint(x: 0, y: -25)
        damageLabel.alpha = 0
        statsContainer.addChild(damageLabel)
        
        // Sequential Fade-In Animations for Stats
        scoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeIn(withDuration: 0.4)
        ]))
        timeLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.fadeIn(withDuration: 0.4)
        ]))
        damageLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeIn(withDuration: 0.4)
        ]))
        
        // 4. BUTTONS
        let buttonY = self.size.height * 0.15
        let btnWidth: CGFloat = 190
        let btnHeight: CGFloat = 38
        let spacing: CGFloat = 20
        
        if isVictory {
            // LEADERBOARD Button (Left)
            let leaderboardBtn = MenuButtonNode(text: "LEADERBOARD", size: CGSize(width: btnWidth, height: btnHeight)) { [weak self] in
                self?.showLeaderboard()
            }
            leaderboardBtn.position = CGPoint(x: screenCenter.x - btnWidth/2 - spacing/2, y: buttonY)
            leaderboardBtn.zPosition = 10
            addChild(leaderboardBtn)
            
            // PLAY AGAIN Button (Right)
            let playAgainBtn = MenuButtonNode(text: "PLAY AGAIN", size: CGSize(width: btnWidth, height: btnHeight)) { [weak self] in
                self?.restartGame()
            }
            playAgainBtn.position = CGPoint(x: screenCenter.x + btnWidth/2 + spacing/2, y: buttonY)
            playAgainBtn.zPosition = 10
            addChild(playAgainBtn)
        } else {
            // MAIN MENU Button (Left)
            let menuBtn = MenuButtonNode(text: "MAIN MENU", size: CGSize(width: btnWidth, height: btnHeight)) { [weak self] in
                self?.goToMainMenu()
            }
            menuBtn.position = CGPoint(x: screenCenter.x - btnWidth/2 - spacing/2, y: buttonY)
            menuBtn.zPosition = 10
            addChild(menuBtn)
            
            // RETRY Button (Right)
            let retryBtn = MenuButtonNode(text: "RETRY", size: CGSize(width: btnWidth, height: btnHeight)) { [weak self] in
                self?.restartGame()
            }
            retryBtn.position = CGPoint(x: screenCenter.x + btnWidth/2 + spacing/2, y: buttonY)
            retryBtn.zPosition = 10
            addChild(retryBtn)
        }
    }
    
    private func createHexagonPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            let angle = CGFloat(i) * CGFloat.pi / 3 - CGFloat.pi / 2
            let point = CGPoint(x: size * cos(angle), y: size * sin(angle))
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func createStarPath(points: Int, innerRadius: CGFloat, outerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angleIncrement = CGFloat.pi / CGFloat(points)
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * angleIncrement - CGFloat.pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func presentNameInputAlert() {
        guard let viewController = self.view?.window?.rootViewController else { return }
        
        let alert = UIAlertController(title: "NOVO RECORDE!", message: "Insere as tuas iniciais (3 letras):", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "AAA"
            textField.autocapitalizationType = .allCharacters
            textField.textAlignment = .center
            
            // Limit text input to 3 characters
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                if let text = textField.text, text.count > 3 {
                    textField.text = String(text.prefix(3))
                }
            }
        }
        
        let submitAction = UIAlertAction(title: "SUBMETER", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines).prefix(3).uppercased() ?? "KTE"
            let finalName = name.isEmpty ? "KTE" : String(name)
            
            LeaderboardManager.shared.submitScore(name: finalName, score: self.score, time: self.time) { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        self?.showLeaderboard()
                    }
                }
            }
        }
        
        alert.addAction(submitAction)
        alert.addAction(UIAlertAction(title: "CANCELAR", style: .cancel, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    private func showLeaderboard() {
        guard leaderboardOverlay == nil else { return }
        
        let overlay = LeaderboardOverlayNode(size: self.size) { [weak self] in
            self?.hideLeaderboard()
        }
        addChild(overlay)
        leaderboardOverlay = overlay
        
        overlay.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        overlay.run(fadeIn)
    }
    
    private func hideLeaderboard() {
        guard let overlay = leaderboardOverlay else { return }
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        overlay.run(fadeOut) { [weak self] in
            overlay.removeFromParent()
            self?.leaderboardOverlay = nil
        }
    }
    
    private func restartGame() {
        guard let skView = self.view else { return }
        
        let transition = SKTransition.fade(withDuration: 0.8)
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .resizeFill
        gameScene.anchorPoint = CGPoint(x: 0, y: 0)
        skView.presentScene(gameScene, transition: transition)
    }
    
    private func goToMainMenu() {
        guard let skView = self.view else { return }
        
        let transition = SKTransition.fade(withDuration: 0.8)
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .resizeFill
        menuScene.anchorPoint = CGPoint(x: 0, y: 0)
        skView.presentScene(menuScene, transition: transition)
    }
}
