//
//  GameViewController.swift
//  Cookie Monster
//
//  Created by Karl Li on 10/5/21.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation
import GoogleMobileAds

class GameViewController: UIViewController, GADBannerViewDelegate, GADFullScreenContentDelegate {
    @IBOutlet weak var scoreLabel:UILabel?
    @IBOutlet weak var timeLabel:UILabel?
    @IBOutlet weak var gameOverImage:UIImageView?
    @IBOutlet weak var bannerView: GADBannerView?
    private var interstitial: GADInterstitialAd?
    
    var scene: GameScene!
    var games = 0 // games played in a session
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

        bannerView?.adUnitID = "ca-app-pub-5721843955514300/9838170530"
        bannerView?.rootViewController = self
        bannerView?.delegate = self
        loadInterstitial()

        startGame()
        backgroundMusic?.play()

        NotificationCenter.default.addObserver(self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    func loadInterstitial() {
        GADInterstitialAd.load(withAdUnitID: "ca-app-pub-5721843955514300/7320652554",
                               request: GADRequest(),
                               completionHandler: { [self] ad, error in
                                if let error = error {
                                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                                    return
                                }
                                interstitial = ad
                                interstitial?.fullScreenContentDelegate = self
                               })
    }

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("bannerViewDidReceiveAd")
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("Failed to load banner ad: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewDidDismissScreen")
    }

    // The ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad: \(error.localizedDescription)")
    }

    // The ad presented full screen content.
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("adDidPresentFullScreenContent")
    }

    // The ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // Resume the music
        backgroundMusic?.play()
        // GADInterstitialAd is a one-time-use object.
        interstitial = nil
        // Load a new interstitial.
        loadInterstitial()
    }

    func updateScoreLabel() {
        scoreLabel?.text = String(score)
    }

    func updateTimeLabel() {
        let min = (seconds / 60) % 60
        let sec = seconds % 60

        timeLabel?.text = String(format: "%02d", min) + ":" + String(format: "%02d", sec)
    }

    @objc func applicationDidEnterBackground() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }

    @objc func applicationDidBecomeActive() {
        if !gameOverImage!.isHidden {
            startGame()
        } else if timer == nil {
            bannerView?.load(GADRequest())

            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                self.seconds += 1
                self.updateTimeLabel()
            }
        }
    }

    @objc func startGame() {
        if let recognizer = tapGestureRecognizer {
            view.removeGestureRecognizer(recognizer)
            tapGestureRecognizer = nil
        }
        
        gameOverImage?.isHidden = true
        scene.isUserInteractionEnabled = true
        bannerView?.load(GADRequest())

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
        games += 1
        timer?.invalidate()
        timer = nil
        
        gameOverImage?.isHidden = false
        scene.isUserInteractionEnabled = false
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.startGame))
        view.addGestureRecognizer(tapGestureRecognizer!)

        if interstitial != nil && games % 3 == 0 {
            backgroundMusic?.stop()
            interstitial?.present(fromRootViewController: self)
        } else {
            loadInterstitial()
        }
    }
    
    func collapse(for cookieBlock: Set<Cookie>) {
        scene.isUserInteractionEnabled = false
        scene.animateCollapsedCookies(for: cookieBlock) {
            self.score += self.scene.game.score(blockSize: cookieBlock.count)
            self.updateScoreLabel()

            let fallingCookies = self.scene.game.removeCookieBlock(cookieBlock)
            self.scene.animateFallingCookies(in: fallingCookies) {
                // self.scene.animateNewCookies(in: columns)
                let shiftingCookies = self.scene.game.compactEmptyColumns()
                self.scene.animateShiftingCookies(in: shiftingCookies) {
                    if self.scene.game.isOver() {
                        let leftOver = self.scene.game.numCookies()
                        let bonus = 20 * (5 - min(5, leftOver))
                        self.scene.animateFireworkBonusScore(fireworks: 3, bonus: bonus) {
                            if bonus > 0 {
                                self.score += bonus
                                self.updateScoreLabel()
                            }
                            self.finishGame()
                        }
                    } else {
                        self.scene.isUserInteractionEnabled = true
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
