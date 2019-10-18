//
//  GameScene.swift
//  Project36
//
//  Created by clarknt on 2019-10-17.
//  Copyright © 2019 clarknt. All rights reserved.
//

import SpriteKit

enum GameState {
    case showingLogo
    case playing
    case dead
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!

    var backgroundMusic: SKAudioNode!

    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!

    var gameState = GameState.showingLogo

    // store physics body so it's not recalculated every time
    // new rocks are added, avoiding slowdowns
    let rockTexture = SKTexture(imageNamed: "rock")
    var rockPhysics: SKPhysicsBody!

    // this constant is not used but will force preloading and caching the texture
    let explosion = SKEmitterNode(fileNamed: "PlayerExplosion")

    var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
        }
    }

    override func didMove(to view: SKView) {
        rockPhysics = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())

        createPlayer()
        createSky()
        createBackground()
        createGround()
        createScore()
        createLogos()

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsWorld.contactDelegate = self

        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "m4a") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .showingLogo:
            gameState = .playing

            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            let activatePlayer = SKAction.run { [unowned self] in
                self.player.physicsBody?.isDynamic = true
                self.startRocks()
            }

            let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
            logo.run(sequence)

        case .playing:
            // cancel previous velocity to avoid having it accumulate
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            // apply upwards impulse
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))

        case .dead:
            if let scene = GameScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
                view?.presentScene(scene, transition: transition)
            }
        }
    }

    func createPlayer() {
        let playerTexture = SKTexture(imageNamed: "player-1")


        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 10
        player.position = CGPoint(x: frame.width / 5, y: frame.height * 0.75)

        addChild(player)

        // pixel perfect physics
        player.physicsBody = SKPhysicsBody(texture: playerTexture, size: playerTexture.size())
        // get notified of any collision
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask
        // for the intro, make the plane NOT respond to physics
        player.physicsBody?.isDynamic = false
        // disable plane bounce
         player.physicsBody?.collisionBitMask = 0

        let frame2 = SKTexture(imageNamed: "player-2")
        let frame3 = SKTexture(imageNamed: "player-3")
        let animation = SKAction.animate(with: [playerTexture, frame2, frame3, frame2], timePerFrame: 0.01) // faster than refresh rate
        let runForever = SKAction.repeatForever(animation)

        player.run(runForever)
    }

    func createSky() {
        let topSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.14, brightness: 0.97, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.67))
        topSky.anchorPoint = CGPoint(x: 0.5, y: 1)

        let bottomSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.16, brightness: 0.96, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.33))
        bottomSky.anchorPoint = CGPoint(x: 0.5, y: 1)

        topSky.position = CGPoint(x: frame.midX, y: frame.height)
        bottomSky.position = CGPoint(x: frame.midX, y: bottomSky.frame.height)

        addChild(topSky)
        addChild(bottomSky)

        bottomSky.zPosition = -40
        topSky.zPosition = -40
    }

    func createBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")

        for i in 0 ... 1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.zPosition = -30
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: (backgroundTexture.size().width * CGFloat(i)) - CGFloat(1 * i), y: 100)
            addChild(background)

            let moveLeft = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 20)
            let moveReset = SKAction.moveBy(x: backgroundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)

            background.run(moveForever)
        }
    }

    func createGround() {
        let groundTexture = SKTexture(imageNamed: "ground")

        for i in 0 ... 1 {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = -10
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)

            // pixel perfect collision detection
            ground.physicsBody = SKPhysicsBody(texture: ground.texture!, size: ground.texture!.size())
            // don't be moved by the collision
            ground.physicsBody?.isDynamic = false

            addChild(ground)

            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)

            ground.run(moveForever)
        }
    }

    func createRocks() {
        let rockTexture = SKTexture(imageNamed: "rock")

        let topRock = SKSpriteNode(texture: rockTexture)
        // allow collision detection
        topRock.physicsBody = rockPhysics.copy() as? SKPhysicsBody
        // disable physics (including gravity) on the rocks
        topRock.physicsBody?.isDynamic = false

        // use the same texture for top, but rotated
        topRock.zRotation = .pi
        topRock.xScale = -1.0

        let bottomRock = SKSpriteNode(texture: rockTexture)
        bottomRock.physicsBody = rockPhysics.copy() as? SKPhysicsBody
        bottomRock.physicsBody?.isDynamic = false

        topRock.zPosition = -20
        bottomRock.zPosition = -20

        // large rectangle positioned just after the rocks and will be used to track
        // when the player has passed through the rocks safely – if they touch that
        // rectangle, they should score a point
        let rockCollision = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 32, height: frame.height))
        // rectangle collision detection this time (faster than pixel-perfect)
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)
        rockCollision.physicsBody?.isDynamic = false

        rockCollision.name = "scoreDetect"

        addChild(topRock)
        addChild(bottomRock)
        addChild(rockCollision)

        let xPosition = frame.width + topRock.frame.width

        let max = CGFloat(frame.height / 3)
        // position of the gap betwwn the rocks
        let yPosition = CGFloat.random(in: -50...max)

        // width of the gap between rocks - the smaller the harder
        let rockDistance: CGFloat = 70

        // position the rocks and animate from right to left
        topRock.position = CGPoint(x: xPosition, y: yPosition + topRock.size.height + rockDistance)
        bottomRock.position = CGPoint(x: xPosition, y: yPosition - rockDistance)
        rockCollision.position = CGPoint(x: xPosition + (rockCollision.size.width * 2), y: frame.midY)

        let endPosition = frame.width + (topRock.frame.width * 2)

        // 6.2 to try to approximate ground speed
        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        topRock.run(moveSequence)
        bottomRock.run(moveSequence)
        rockCollision.run(moveSequence)
    }

    func startRocks() {
        let create = SKAction.run { [unowned self] in
            self.createRocks()
        }

        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)

        run(repeatForever)
    }

    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.fontSize = 24

        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontColor = UIColor.black

        addChild(scoreLabel)
    }

    override func update(_ currentTime: TimeInterval) {
        guard player != nil else { return }

        // angle the plane slightly while going up or down
        let value = player.physicsBody!.velocity.dy * 0.001
        let rotate = SKAction.rotate(toAngle: value, duration: 0.1)

        player.run(rotate)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // collision with the score detection rectangle?
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }

            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)

            score += 1

            return
        }

        // avoid possible double collision detection (player against rectangle,
        // then rectangle against player)
        guard contact.bodyA.node != nil && contact.bodyB.node != nil else {
            return
        }

        if contact.bodyA.node == player || contact.bodyB.node == player {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") {
                explosion.position = player.position
                addChild(explosion)
            }

            let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            run(sound)

            gameOver.alpha = 1
            gameState = .dead
            backgroundMusic.run(SKAction.stop())

            player.removeFromParent()
            speed = 0
        }
    }

    func createLogos() {
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)

        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0
        addChild(gameOver)
    }
}