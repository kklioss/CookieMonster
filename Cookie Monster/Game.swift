//
//  Game.swift
//  Cookie Monster
//
//  Created by Karl Li on 10/5/21.
//

import Foundation

class Game {
    // Column-wise matrix of cookies. nil indicates no cookie.
    private var cookies = [[Cookie?]]()
    
    init(width: Int, height: Int) {
        for x in 0..<width {
            var column = [Cookie?]()
            for y in 0..<height {
                let cookie = Cookie(x: x, y: y, type: CookieType.random())
                column.append(cookie)
            }
            cookies.append(column)
        }
    }
    
    func numCookies() -> Int {
        var n = 0
        for x in 0..<cookies.count {
            for cookie in cookies[x] {
                if cookie != nil {
                    n += 1
                }
            }
        }
        return n
    }

    func score(blockSize: Int) -> Int {
        return blockSize < 2 ? 0 : blockSize * (blockSize - 1)
    }
    
    func cookieAt(_ x: Int, _ y: Int) -> Cookie? {
        return cookies[x][y]
    }
    
    func removeCookieBlock(_ cookieBlock: Set<Cookie>) -> [[Cookie]] {
        for cookie in cookieBlock {
            cookies[cookie.x][cookie.y] = nil
        }
        return fillHoles()
    }
    
    func fillHoles() -> [[Cookie]] {
        var fallingCookieColumns: [[Cookie]] = []
        for x in 0..<cookies.count {
            var fallingCookieColumn = [Cookie]()
            let height = cookies[x].count
            for y in 0..<height {
                if cookies[x][y] == nil {
                    for lookup in (y + 1)..<height {
                        if let cookie = cookies[x][lookup] {
                            cookies[x][lookup] = nil
                            cookies[x][y] = cookie
                            cookie.y = y
                            fallingCookieColumn.append(cookie)
                            break
                        }
                    }
                }
            }
            
            if !fallingCookieColumn.isEmpty {
                fallingCookieColumns.append(fallingCookieColumn)
            }
        }
        
        return fallingCookieColumns
    }
    
    func compactEmptyColumns() -> [[Cookie]] {
        var shiftingCookieColumns: [[Cookie]] = []
        for x in 0..<cookies.count {
            if isEmptyColumn(cookies[x]) {
                for lookup in (x + 1)..<cookies.count {
                    if !isEmptyColumn(cookies[lookup]) {
                        cookies[x] = cookies[lookup]
                        cookies[x].forEach { $0?.x = x }
                        cookies[lookup] = [Cookie?](repeating: nil, count: cookies[lookup].count)
                        shiftingCookieColumns.append(cookies[x].compactMap{$0})
                        break
                    }
                }
            }
        }
        return shiftingCookieColumns
    }

    func isEmptyColumn(_ column: [Cookie?]) -> Bool {
        return column.allSatisfy({ $0 == nil })
    }
    
    /**
     * Return the same cookie type  block.
     */
    func getCookieBlock(cookie: Cookie, cookieType: CookieType, blockSet: inout Set<Cookie>) {
        if cookie.type == cookieType && !blockSet.contains(cookie) {
            blockSet.insert(cookie)
            let x = cookie.x
            let y = cookie.y

            if x > 0 {
                if let neighbor = cookieAt(x - 1, y) {
                    getCookieBlock(cookie: neighbor, cookieType: cookieType, blockSet: &blockSet)
                }
            }
        
            if x < cookies.count - 1 {
                if let neighbor = cookieAt(x + 1, y) {
                    getCookieBlock(cookie: neighbor, cookieType: cookieType, blockSet: &blockSet)
                }
            }
        
            if y > 0 {
                if let neighbor = cookieAt(x, y - 1) {
                    getCookieBlock(cookie: neighbor, cookieType: cookieType, blockSet: &blockSet)
                }
            }
        
            if y < cookies[x].count - 1 {
                if let neighbor = cookieAt(x, y + 1) {
                    getCookieBlock(cookie: neighbor, cookieType: cookieType, blockSet: &blockSet)
                }
            }
        }
    }
    
    func isOver() -> Bool {
        for column in cookies {
            for cell in column {
                if let cookie = cell {
                    var blockSet: Set<Cookie> = []
                    getCookieBlock(cookie: cookie, cookieType: cookie.type, blockSet: &blockSet)
                    if blockSet.count > 1 {
                        return false
                    }
                }
            }
        }
        return true
    }
}
