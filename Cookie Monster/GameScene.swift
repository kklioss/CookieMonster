//
//  GameScene.swift
//  Cookie Monster
//
//  Copyright (c) 2021 Karl Li. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private let tapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    private let invalidTapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    private let collapseSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    private let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    private let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    private let tileSize = CGSize(width: 32, height: 36)
    private let gameLayer = SKNode()
    private let tilesLayer = SKNode()
    private let cropLayer = SKCropNode()
    private let maskLayer = SKNode()
    private let cookieLayer = SKNode()
    private let scoreLabel = SKLabelNode(fontNamed: "HVD Comic Serif Pro")
    private var scoreMoveAction: SKAction!
    private var layerPosition: CGPoint!

    // The number of cookie columns
    private var width: Int!
    // THe number of cookie rows
    private var height: Int!
    // Selected cookie block
    private var selectedCookies: Set<Cookie> = []
    
    var game: Game!
    var controller: GameViewController!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.size = size
        addChild(background)
        addChild(gameLayer)
        
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = UIColor.white
        scoreLabel.zPosition = 300
        
        // set backgound to score label
        let scoreLabelBackground = SKSpriteNode(imageNamed: "Tile")
        scoreLabelBackground.size = CGSize(width: 80, height:40)
        scoreLabelBackground.position = CGPoint(x: CGFloat(0), y: CGFloat(12))
        scoreLabelBackground.zPosition = -1
        scoreLabel.addChild(scoreLabelBackground)

        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 600), duration: 0.3)
        moveAction.timingMode = .easeOut
        scoreMoveAction = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        
        height = Int(size.height / tileSize.height) - 6 // leave 3 rows margin in top and bottom
        width = Int(size.width / tileSize.width)
        
        let layerPosition = CGPoint(
            x: -tileSize.width * CGFloat(width) / 2,
            y: -tileSize.height * CGFloat(height) / 2)
        
        tilesLayer.position = layerPosition
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        gameLayer.addChild(tilesLayer)
        gameLayer.addChild(cropLayer)
        
        cookieLayer.position = layerPosition
        cropLayer.addChild(cookieLayer)
        
        // add tiles
        for x in 0..<width {
            for y in 0..<height {
                let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                tileNode.size = tileSize
                tileNode.position = pointFor(x, y)
                maskLayer.addChild(tileNode)
            }
        }
        
        for x in 0...width {
            for y in 0...height {
                let topLeft     = (x > 0) && (y < height) ? 1 : 0
                let bottomLeft  = (x > 0) && (y > 0) ? 1 : 0
                let topRight    = (x < width) && (y < height) ? 1 : 0
                let bottomRight = (x < width) && (y > 0) ? 1 : 0
                
                var tileId = topLeft
                tileId = tileId | topRight << 1
                tileId = tileId | bottomLeft << 2
                tileId = tileId | bottomRight << 3
                
                // Values 0 (no tiles), 6 and 9 (two opposite tiles) are invalid.
                if tileId != 0 && tileId != 6 && tileId != 9 {
                    let tileNode = SKSpriteNode(imageNamed: String(format: "Tile_%ld", tileId))
                    tileNode.size = tileSize
                    var point = pointFor(x, y)
                    point.x -= tileSize.width / 2
                    point.y -= tileSize.height / 2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func newGame() {
        game = Game(width: width, height: height)
        
        cookieLayer.removeAllChildren()
        run(addCookieSound)
        for x in 0..<width {
            for y in 0..<height {
                if let cookie = game.cookieAt(x, y) {
                    let sprite = SKSpriteNode(imageNamed: cookie.type.spriteName)
                    sprite.size = tileSize
                    sprite.position = pointFor(x, y)
                    cookieLayer.addChild(sprite)
                    cookie.sprite = sprite
                }
            }
        }
    }
    
    private func pointFor(_ x: Int, _ y: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(x) * tileSize.width + tileSize.width / 2,
            y: CGFloat(y) * tileSize.height + tileSize.height / 2)
    }
    
    func showSelectionIndicator(of cookies: Set<Cookie>) {
        for cookie in cookies {
            if let sprite = cookie.sprite {
                let selectionSprite = SKSpriteNode()
                let texture = SKTexture(imageNamed: cookie.type.highlightedSpriteName)
                selectionSprite.name = "selection"
                selectionSprite.size = tileSize
                selectionSprite.run(SKAction.setTexture(texture))
                
                sprite.addChild(selectionSprite)
                selectionSprite.alpha = 1.0
            }
        }
    }
    
    func hideSelectionIndicator(of cookies: Set<Cookie>) {
        for cookie in cookies {
            if let sprite = cookie.sprite {
                if let selectionSprite = sprite.childNode(withName: "selection") {
                    selectionSprite.run(SKAction.sequence([
                                                            SKAction.fadeOut(withDuration: 0.3),
                                                            SKAction.removeFromParent()]))
                }
            }
        }
    }
    
    // Convert touch point to cookie coordinates
    private func convertPoint(_ point: CGPoint) -> (success: Bool, x: Int, y: Int) {
        if point.x >= 0 && point.x < CGFloat(width) * tileSize.width &&
            point.y >= 0 && point.y < CGFloat(height) * tileSize.height {
            return (true, Int(point.x / tileSize.width), Int(point.y / tileSize.height))
        } else {
            return (false, 0, 0)  // invalid location
        }
    }
    
    private func animateScore() {
        scoreLabel.run(scoreMoveAction)
    }
    
    func animateCollapsedCookies(for cookieBlock: Set<Cookie>, completion: @escaping () -> Void) {
        scoreLabel.run(scoreMoveAction)
        
        for cookie in cookieBlock {
            if let sprite = cookie.sprite {
                if sprite.action(forKey: "removing") == nil {
                    let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                    scaleAction.timingMode = .easeOut
                    sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]), withKey: "removing")
                }
            }
        }
        
        run(collapseSound)
        run(SKAction.wait(forDuration: 0.3), completion: completion)
    }

    func animateFallingCookies(in fallingCookieColumns: [[Cookie]], completion: @escaping () -> Void) {
        var longestDuration: TimeInterval = 0
        for column in fallingCookieColumns {
            for index in 0..<column.count {
                let cookie = column[index]
                let newPosition = pointFor(cookie.x, cookie.y)
                let delay = 0.05 + 0.15 * TimeInterval(index)
                let sprite = cookie.sprite!   // sprite always exists at this point
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / tileSize.height) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(SKAction.sequence([SKAction.wait(forDuration: delay),
                                              SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }

    func animateShiftingCookies(in shiftingCookieColumns: [[Cookie]], completion: @escaping () -> Void) {
        var longestDuration: TimeInterval = 0
        for index in 0..<shiftingCookieColumns.count {
            let column = shiftingCookieColumns[index]
            for cookie in column {
                let newPosition = pointFor(cookie.x, cookie.y)
                let delay = 0.05 + 0.15 * TimeInterval(index)
                let sprite = cookie.sprite!   // sprite always exists at this point
                let duration = TimeInterval(((sprite.position.x - newPosition.x) / tileSize.width) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(SKAction.sequence([SKAction.wait(forDuration: delay),
                                              SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    override func didMove(to view: SKView) {
        
    }
        
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookieLayer)
        let (success, x, y) = convertPoint(location)
        if success, let cookie = game.cookieAt(x, y) {
            if !selectedCookies.isEmpty && !selectedCookies.contains(cookie) {
                hideSelectionIndicator(of: selectedCookies)
                selectedCookies.removeAll()
                scoreLabel.removeFromParent()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookieLayer)
        let (success, x, y) = convertPoint(location)
        if success, let cookie = game.cookieAt(x, y) {
            if selectedCookies.contains(cookie) {
                controller.collapse(for: selectedCookies)
                selectedCookies.removeAll()
            } else {
                game.getCookieBlock(cookie: cookie, cookieType: cookie.type, blockSet: &selectedCookies)
                let score = game.score(blockSize: selectedCookies.count)
                if score > 0 {
                    showSelectionIndicator(of: selectedCookies)
                    scoreLabel.text = String(format: "%ld", score)
                    scoreLabel.position = location
                    if !cookieLayer.contains(scoreLabel) {
                        cookieLayer.addChild(scoreLabel)
                    }
                    run(tapSound)
                } else {
                    selectedCookies.removeAll()
                    run(invalidTapSound)
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func animateGameOver(_ completion: @escaping () -> Void) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    
    func animateStartGame(_ completion: @escaping () -> Void) {
        gameLayer.isHidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeOut
        gameLayer.run(action, completion: completion)
    }
}
