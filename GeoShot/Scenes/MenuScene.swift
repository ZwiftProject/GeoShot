//
//  MenuScene.swift
//  GeoShot
//
//  Created by Joao Ribeiro on 20/05/2026.
//

import SpriteKit

class MenuScene: SKScene {
    
    private var playerIcon: SKShapeNode!
    private var leaderboardOverlay: LeaderboardOverlayNode?
    private var settingsOverlay: SettingsOverlayNode?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
        setupUI()
    }
    
    private func setupUI() {
        // Clear any previous nodes if re-initialized
        self.removeAllChildren()
        
        let screenCenter = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        // 1. TITLE: "GeoShot"
        // Title Container for Glow Effect
        let titleContainer = SKNode()
        let titleY = self.size.height * 0.82
        titleContainer.position = CGPoint(x: screenCenter.x, y: titleY)
        addChild(titleContainer)
        
        // Background Glow Labels (offset to simulate thick glow/drop shadow)
        let glowOffsets = [
            CGPoint(x: -2, y: -2), CGPoint(x: 2, y: -2),
            CGPoint(x: -2, y: 2), CGPoint(x: 2, y: 2),
            CGPoint(x: 0, y: -3), CGPoint(x: 0, y: 3),
            CGPoint(x: -3, y: 0), CGPoint(x: 3, y: 0)
        ]
        for offset in glowOffsets {
            let glowLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            glowLabel.text = "GeoShot"
            glowLabel.fontSize = 64
            glowLabel.fontColor = .cyan
            glowLabel.position = offset
            glowLabel.zPosition = 1
            glowLabel.alpha = 0.5
            titleContainer.addChild(glowLabel)
        }
        
        // Foreground Main White Label
        let mainTitle = SKLabelNode(fontNamed: "Menlo-Bold")
        mainTitle.text = "GeoShot"
        mainTitle.fontSize = 64
        mainTitle.fontColor = .white
        mainTitle.position = .zero
        mainTitle.zPosition = 2
        titleContainer.addChild(mainTitle)
        
        // Subtle Pulse Animation for Title
        let pulseUp = SKAction.scale(to: 1.03, duration: 1.2)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.97, duration: 1.2)
        pulseDown.timingMode = .easeInEaseOut
        let pulseSeq = SKAction.sequence([pulseUp, pulseDown])
        titleContainer.run(SKAction.repeatForever(pulseSeq))
        
        // 2. CENTER ICON: Spinning Player Node
        // Centered coordinates of player shape to rotate perfectly around (0,0)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -9, y: 13))        // topo
        path.addLine(to: CGPoint(x: 21, y: 0))      // ponta direita (mais longa)
        path.addLine(to: CGPoint(x: -9, y: -13))    // fundo
        path.addLine(to: CGPoint(x: -21, y: 0))     // esquerda
        path.closeSubpath()
        
        playerIcon = SKShapeNode(path: path)
        playerIcon.fillColor = .cyan
        playerIcon.strokeColor = .white
        playerIcon.lineWidth = 2.0
        playerIcon.glowWidth = 4.0 // Neon vector glow
        let iconY = self.size.height * 0.53
        playerIcon.position = CGPoint(x: screenCenter.x, y: iconY)
        playerIcon.zPosition = 5
        playerIcon.setScale(3.5) // Scale up to make it prominent
        addChild(playerIcon)
        
        // Infinite rotation action
        let rotateAction = SKAction.rotate(byAngle: -CGFloat.pi * 2, duration: 6.0)
        playerIcon.run(SKAction.repeatForever(rotateAction))
        
        // 3. BUTTONS
        let buttonStartY = self.size.height * 0.30
        let buttonSpacing: CGFloat = 46
        let btnSize = CGSize(width: 280, height: 38)
        
        // PLAY Button
        let playButton = MenuButtonNode(text: "PLAY", size: btnSize) { [weak self] in
            self?.startGame()
        }
        playButton.position = CGPoint(x: screenCenter.x, y: buttonStartY)
        playButton.zPosition = 10
        addChild(playButton)
        
        // LEADERBOARD Button
        let leaderboardButton = MenuButtonNode(text: "LEADERBOARD", size: btnSize) { [weak self] in
            self?.showLeaderboard()
        }
        leaderboardButton.position = CGPoint(x: screenCenter.x, y: buttonStartY - buttonSpacing)
        leaderboardButton.zPosition = 10
        addChild(leaderboardButton)
        
        // SETTINGS Button
        let settingsButton = MenuButtonNode(text: "SETTINGS", size: btnSize) { [weak self] in
            self?.showSettings()
        }
        settingsButton.position = CGPoint(x: screenCenter.x, y: buttonStartY - 2 * buttonSpacing)
        settingsButton.zPosition = 10
        addChild(settingsButton)
    }
    
    private func startGame() {
        guard let skView = self.view else { return }
        
        // Visual feedback flash before transition
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in self?.backgroundColor = .cyan },
            SKAction.wait(forDuration: 0.05),
            SKAction.run { [weak self] in self?.backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0) }
        ])
        
        self.run(flash) {
            let transition = SKTransition.fade(withDuration: 0.8)
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .resizeFill
            gameScene.anchorPoint = CGPoint(x: 0, y: 0)
            skView.presentScene(gameScene, transition: transition)
        }
    }
    
    private func showLeaderboard() {
        guard leaderboardOverlay == nil else { return }
        
        let overlay = LeaderboardOverlayNode(size: self.size) { [weak self] in
            self?.hideLeaderboard()
        }
        addChild(overlay)
        leaderboardOverlay = overlay
        
        // Animate overlay in
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
    
    private func showSettings() {
        guard settingsOverlay == nil else { return }
        
        let overlay = SettingsOverlayNode(size: self.size) { [weak self] in
            self?.hideSettings()
        }
        addChild(overlay)
        settingsOverlay = overlay
        
        overlay.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        overlay.run(fadeIn)
    }
    
    private func hideSettings() {
        guard let overlay = settingsOverlay else { return }
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        overlay.run(fadeOut) { [weak self] in
            overlay.removeFromParent()
            self?.settingsOverlay = nil
        }
    }
}

// MARK: - Menu Button Node
class MenuButtonNode: SKNode {
    let action: () -> Void
    private var border: SKShapeNode!
    private var label: SKLabelNode!
    private var isPressed = false
    private var buttonSize: CGSize
    
    init(text: String, size: CGSize, action: @escaping () -> Void) {
        self.action = action
        self.buttonSize = size
        super.init()
        self.isUserInteractionEnabled = true
        
        // Border shape
        let path = CGPath(roundedRect: CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height), cornerWidth: 8, cornerHeight: 8, transform: nil)
        
        border = SKShapeNode(path: path)
        border.strokeColor = .cyan
        border.fillColor = SKColor(red: 0.07, green: 0.07, blue: 0.1, alpha: 0.9)
        border.lineWidth = 2.0
        border.glowWidth = 2.0
        border.zPosition = 1
        addChild(border)
        
        // Text Label
        label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 2
        addChild(label)
    }
    
    func updateText(_ text: String) {
        label.text = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPressed = true
        let scale = SKAction.scale(to: 0.95, duration: 0.08)
        let colorChange = SKAction.run { [weak self] in
            self?.border.fillColor = .cyan
            self?.label.fontColor = .black
        }
        run(SKAction.group([scale, colorChange]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPressed else { return }
        isPressed = false
        
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.08)
        let colorReset = SKAction.run { [weak self] in
            self?.border.fillColor = SKColor(red: 0.07, green: 0.07, blue: 0.1, alpha: 0.9)
            self?.label.fontColor = .white
        }
        
        run(SKAction.group([scaleBack, colorReset])) { [weak self] in
            guard let self = self else { return }
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            // Check if touch ended inside button bounds
            let halfW = self.buttonSize.width / 2
            let halfH = self.buttonSize.height / 2
            if location.x >= -halfW && location.x <= halfW && location.y >= -halfH && location.y <= halfH {
                self.action()
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPressed = false
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.08)
        let colorReset = SKAction.run { [weak self] in
            self?.border.fillColor = SKColor(red: 0.07, green: 0.07, blue: 0.1, alpha: 0.9)
            self?.label.fontColor = .white
        }
        run(SKAction.group([scaleBack, colorReset]))
    }
}

// MARK: - Leaderboard Overlay Node
class LeaderboardOverlayNode: SKNode {
    private let closeAction: () -> Void
    private let panel: SKShapeNode
    private let panelSize: CGSize
    
    init(size: CGSize, closeAction: @escaping () -> Void) {
        self.closeAction = closeAction
        
        // Main panel size
        self.panelSize = CGSize(width: size.width * 0.65, height: size.height * 0.75)
        let panelPath = CGPath(roundedRect: CGRect(x: -panelSize.width/2, y: -panelSize.height/2, width: panelSize.width, height: panelSize.height), cornerWidth: 12, cornerHeight: 12, transform: nil)
        
        self.panel = SKShapeNode(path: panelPath)
        self.panel.fillColor = SKColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0)
        self.panel.strokeColor = .cyan
        self.panel.lineWidth = 2.5
        self.panel.glowWidth = 2.5
        self.panel.zPosition = 101
        self.panel.position = CGPoint(x: size.width/2, y: size.height/2)
        
        super.init()
        self.isUserInteractionEnabled = true
        
        // Full screen dark semi-transparent tint
        let bgOverlay = SKShapeNode(rectOf: size)
        bgOverlay.fillColor = SKColor(white: 0.0, alpha: 0.8)
        bgOverlay.strokeColor = .clear
        bgOverlay.zPosition = 100
        bgOverlay.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(bgOverlay)
        addChild(panel)
        
        // Leaderboard Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "LEADERBOARD"
        title.fontSize = 26
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelSize.height/2 - 45)
        title.zPosition = 102
        panel.addChild(title)
        
        // Loading Label
        let loadingLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        loadingLabel.text = "A CARREGAR..."
        loadingLabel.fontSize = 18
        loadingLabel.fontColor = .lightGray
        loadingLabel.position = CGPoint(x: 0, y: 0)
        loadingLabel.zPosition = 102
        panel.addChild(loadingLabel)
        
        // Close button at bottom
        let closeBtn = MenuButtonNode(text: "CLOSE", size: CGSize(width: 140, height: 40)) { [weak self] in
            self?.closeAction()
        }
        closeBtn.position = CGPoint(x: 0, y: -panelSize.height/2 + 45)
        closeBtn.zPosition = 103
        panel.addChild(closeBtn)
        
        // Load data from Firebase
        LeaderboardManager.shared.fetchTopScores { [weak self] records in
            DispatchQueue.main.async {
                loadingLabel.removeFromParent()
                self?.displayRecords(records)
            }
        }
    }
    
    private func displayRecords(_ records: [LeaderboardRecord]) {
        if records.isEmpty {
            let emptyLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            emptyLabel.text = "SEM RECORDES"
            emptyLabel.fontSize = 18
            emptyLabel.fontColor = .cyan
            emptyLabel.position = CGPoint(x: 0, y: 0)
            emptyLabel.zPosition = 102
            panel.addChild(emptyLabel)
            return
        }
        
        var startY = panelSize.height/2 - 100
        for (index, record) in records.enumerated() {
            let rank = index + 1
            let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            nameLabel.text = "\(rank). \(record.name)"
            nameLabel.fontSize = 18
            nameLabel.fontColor = .cyan
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: -panelSize.width/3, y: startY)
            nameLabel.zPosition = 102
            panel.addChild(nameLabel)
            
            let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            scoreLabel.text = "\(record.score) PTS"
            scoreLabel.fontSize = 18
            scoreLabel.fontColor = .white
            scoreLabel.horizontalAlignmentMode = .right
            scoreLabel.position = CGPoint(x: panelSize.width/3, y: startY)
            scoreLabel.zPosition = 102
            panel.addChild(scoreLabel)
            
            startY -= 35
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}

// MARK: - Settings Overlay Node
class SettingsOverlayNode: SKNode {
    private let closeAction: () -> Void
    private var musicBtn: MenuButtonNode!
    private var syncBtn: MenuButtonNode?
    private var loginBtn: MenuButtonNode?
    private var statusLabel: SKLabelNode!
    private let panel: SKShapeNode
    private let panelSize: CGSize
    
    private var isMusicEnabled: Bool {
        get {
            return UserDefaults.standard.object(forKey: "music_enabled") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "music_enabled")
        }
    }
    
    init(size: CGSize, closeAction: @escaping () -> Void) {
        self.closeAction = closeAction
        
        // Main panel size
        self.panelSize = CGSize(width: size.width * 0.60, height: size.height * 0.70)
        let panelPath = CGPath(roundedRect: CGRect(x: -panelSize.width/2, y: -panelSize.height/2, width: panelSize.width, height: panelSize.height), cornerWidth: 12, cornerHeight: 12, transform: nil)
        
        self.panel = SKShapeNode(path: panelPath)
        self.panel.fillColor = SKColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0)
        self.panel.strokeColor = .cyan
        self.panel.lineWidth = 2.5
        self.panel.glowWidth = 2.5
        self.panel.zPosition = 101
        self.panel.position = CGPoint(x: size.width/2, y: size.height/2)
        
        super.init()
        self.isUserInteractionEnabled = true
        
        // Full screen dark semi-transparent tint
        let bgOverlay = SKShapeNode(rectOf: size)
        bgOverlay.fillColor = SKColor(white: 0.0, alpha: 0.8)
        bgOverlay.strokeColor = .clear
        bgOverlay.zPosition = 100
        bgOverlay.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(bgOverlay)
        addChild(panel)
        
        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "SETTINGS"
        title.fontSize = 26
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelSize.height/2 - 45)
        title.zPosition = 102
        panel.addChild(title)
        
        // Account Status Label
        statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        statusLabel.fontSize = 12
        statusLabel.fontColor = .lightGray
        statusLabel.position = CGPoint(x: 0, y: 70)
        statusLabel.zPosition = 102
        panel.addChild(statusLabel)
        
        updateAccountStatusLabel()
        
        // Create buttons depending on login state
        setupAuthButtons()
        
        // Music button
        let initialMusicText = isMusicEnabled ? "MUSIC: ON" : "MUSIC: OFF"
        musicBtn = MenuButtonNode(text: initialMusicText, size: CGSize(width: 220, height: 38)) { [weak self] in
            self?.toggleMusic()
        }
        musicBtn.position = CGPoint(x: 0, y: -70)
        musicBtn.zPosition = 102
        panel.addChild(musicBtn)
        
        // Close button at bottom
        let closeBtn = MenuButtonNode(text: "CLOSE", size: CGSize(width: 140, height: 38)) { [weak self] in
            self?.closeAction()
        }
        closeBtn.position = CGPoint(x: 0, y: -panelSize.height/2 + 40)
        closeBtn.zPosition = 103
        panel.addChild(closeBtn)
    }
    
    private func updateAccountStatusLabel() {
        if let email = LeaderboardManager.shared.userEmail {
            statusLabel.text = "CONTA: \(email.uppercased())"
            statusLabel.fontColor = .green
        } else {
            statusLabel.text = "CONTA: TEMPORÁRIA (LOCAL)"
            statusLabel.fontColor = .lightGray
        }
    }
    
    private func setupAuthButtons() {
        syncBtn?.removeFromParent()
        loginBtn?.removeFromParent()
        
        if LeaderboardManager.shared.isAnonymous {
            // VINCULAR Button
            let sync = MenuButtonNode(text: "VINCULAR CONTA", size: CGSize(width: 220, height: 38)) { [weak self] in
                self?.presentSyncAccountAlert()
            }
            sync.position = CGPoint(x: 0, y: 25)
            sync.zPosition = 102
            panel.addChild(sync)
            self.syncBtn = sync
            
            // LOGIN Button
            let login = MenuButtonNode(text: "INICIAR SESSÃO", size: CGSize(width: 220, height: 38)) { [weak self] in
                self?.presentLoginAlert()
            }
            login.position = CGPoint(x: 0, y: -20)
            login.zPosition = 102
            panel.addChild(login)
            self.loginBtn = login
        } else {
            // Se já tem conta permanente, mostrar apenas botão de Logout
            let logout = MenuButtonNode(text: "TERMINAR SESSÃO", size: CGSize(width: 220, height: 38)) { [weak self] in
                self?.handleLogout()
            }
            logout.position = CGPoint(x: 0, y: 10)
            logout.zPosition = 102
            panel.addChild(logout)
            self.syncBtn = logout
        }
    }
    
    private func toggleMusic() {
        isMusicEnabled.toggle()
        let text = isMusicEnabled ? "MUSIC: ON" : "MUSIC: OFF"
        musicBtn.updateText(text)
    }
    
    private func presentSyncAccountAlert() {
        guard let viewController = self.scene?.view?.window?.rootViewController else { return }
        
        let alert = UIAlertController(title: "VINCULAR CONTA", message: "Regista um email e password para guardar e sincronizar os teus recordes online:", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "email@exemplo.com"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }
        alert.addTextField { textField in
            textField.placeholder = "Palavra-passe (mín. 6 caracteres)"
            textField.isSecureTextEntry = true
        }
        
        let submitAction = UIAlertAction(title: "REGISTAR", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let email = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let password = alert.textFields?[1].text ?? ""
            
            if email.isEmpty || password.count < 6 {
                self.showErrorAlert(message: "Por favor insere um email válido e password com pelo menos 6 caracteres.")
                return
            }
            
            LeaderboardManager.shared.linkAccount(email: email, password: password) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.updateAccountStatusLabel()
                        self?.setupAuthButtons()
                        self?.showSuccessAlert(message: "Conta vinculada com sucesso!")
                    case .failure(let error):
                        self?.showErrorAlert(message: error.localizedDescription)
                    }
                }
            }
        }
        
        alert.addAction(submitAction)
        alert.addAction(UIAlertAction(title: "CANCELAR", style: .cancel, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    private func presentLoginAlert() {
        guard let viewController = self.scene?.view?.window?.rootViewController else { return }
        
        let alert = UIAlertController(title: "INICIAR SESSÃO", message: "Introduz os teus dados para recuperar o teu perfil noutro dispositivo:", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "email@exemplo.com"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }
        alert.addTextField { textField in
            textField.placeholder = "Palavra-passe"
            textField.isSecureTextEntry = true
        }
        
        let submitAction = UIAlertAction(title: "ENTRAR", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let email = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let password = alert.textFields?[1].text ?? ""
            
            if email.isEmpty || password.isEmpty {
                self.showErrorAlert(message: "Por favor insere o email e password.")
                return
            }
            
            LeaderboardManager.shared.signInWithEmail(email: email, password: password) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.updateAccountStatusLabel()
                        self?.setupAuthButtons()
                        self?.showSuccessAlert(message: "Iniciou sessão com sucesso!")
                    case .failure(let error):
                        self?.showErrorAlert(message: error.localizedDescription)
                    }
                }
            }
        }
        
        alert.addAction(submitAction)
        alert.addAction(UIAlertAction(title: "CANCELAR", style: .cancel, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    private func handleLogout() {
        UserDefaults.standard.removeObject(forKey: "firebase_id_token")
        UserDefaults.standard.removeObject(forKey: "firebase_user_id")
        UserDefaults.standard.removeObject(forKey: "firebase_user_email")
        UserDefaults.standard.synchronize()
        
        LeaderboardManager.shared.signInAnonymously { [weak self] success in
            DispatchQueue.main.async {
                self?.updateAccountStatusLabel()
                self?.setupAuthButtons()
                self?.showSuccessAlert(message: "Terminou sessão.")
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        guard let viewController = self.scene?.view?.window?.rootViewController else { return }
        let alert = UIAlertController(title: "ERRO", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    private func showSuccessAlert(message: String) {
        guard let viewController = self.scene?.view?.window?.rootViewController else { return }
        let alert = UIAlertController(title: "SUCESSO", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
