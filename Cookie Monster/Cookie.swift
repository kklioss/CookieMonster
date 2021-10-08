//
//  Cookie.swift
//  Cookie Monster
//
//  Created by Karl Li on 10/5/21.
//

import Foundation
import SpriteKit

// MARK: - CookieType
enum CookieType: Int {
    case croissant = 0, cupcake, danish, donut, macaroon, sugarCookie
    
    var spriteName: String {
        let spriteNames = [
            "Croissant",
            "Cupcake",
            "Danish",
            "Donut",
            "Macaroon",
            "SugarCookie"]
        
        return spriteNames[rawValue]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(6)))!
    }
}

// MARK: - Cookie
class Cookie: CustomStringConvertible, Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(y * 100 + x)
    }
    
    static func ==(lhs: Cookie, rhs: Cookie) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    var description: String {
        return "\(type) at (\(x),\(y))"
    }
    
    var x: Int
    var y: Int
    let type: CookieType
    var sprite: SKSpriteNode?
    
    init(x: Int, y: Int, type: CookieType) {
        self.x = x
        self.y = y
        self.type = type
    }
}
