//
//  GameViewController.swift
//  Cookie Monster
//
//  Copyright (c) 2021 Karl Li. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {
    @IBOutlet weak var scoreLabel:UILabel?
    @IBOutlet weak var timeLabel:UILabel?
    @IBOutlet weak var shuffleButton:UIButton?
    @IBOutlet weak var gameOverImage:UIImageView?
    
    var scene: GameScene!
    var score = 0
    var seconds = 0
    var timer:Timer?
    var tapGestureRecognizer: UITapGestureRecognizer?

    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
          return nil
        }
        do {
          let player = try AVAudioPlayer(contentsOf: url)
          player.numberOfLoops = -1
          return player
        } catch {
          return nil
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            scene = GameScene(size: view.bounds.size)
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            scene.controller = self
            // Present the scene
            view.presentScene(scene)
        }

        startGame()
        backgroundMusic?.play()
    }
    
    @IBAction func shuffleButtonTapped() {
        startGame()
    }
    
    func updateScoreLabel() {
        scoreLabel?.text = String(score)
    }
    
    func updateTimeLabel() {
        let min = (seconds / 60) % 60
        let sec = seconds % 60

        timeLabel?.text = String(format: "%02d", min) + ":" + String(format: "%02d", sec)
    }
    
    @objc func startGame() {
        if let recognizer = tapGestureRecognizer {
            view.removeGestureRecognizer(recognizer)
            tapGestureRecognizer = nil
        }
        
        gameOverImage?.isHidden = true
        scene.isUserInteractionEnabled = true

        score = 0
        seconds = 0

        updateScoreLabel()
        updateTimeLabel()
        scene.newGame()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.seconds += 1
            self.updateTimeLabel()
        }
    }
    
    func finishGame() {
        timer?.invalidate()
        timer = nil
        
        gameOverImage?.isHidden = false
        scene.isUserInteractionEnabled = false
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.startGame))
        view.addGestureRecognizer(tapGestureRecognizer!)
    }
    
    func collapse(for cookieBlock: Set<Cookie>) {
        scene.animateCollapsedCookies(for: cookieBlock) {
            self.score += self.scene.game.score(blockSize: cookieBlock.count)
            self.updateScoreLabel()

            let fallingCookies = self.scene.game.removeCookieBlock(cookieBlock)
            self.scene.animateFallingCookies(in: fallingCookies) {
                // self.scene.animateNewCookies(in: columns)
                let shiftingCookies = self.scene.game.compactEmptyColumns()
                self.scene.animateShiftingCookies(in: shiftingCookies) {
                    if self.scene.game.isOver() {
                        self.finishGame()
                    }
                }
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
