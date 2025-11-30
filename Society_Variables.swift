//
//  Society_Variables.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import Foundation
import SwiftUI

enum Stage: String, Codable, CaseIterable {
    case campaigning = "Campaigning"
    case voting = "Voting"
    case running = "Running"
    case ended = "Ended"
}


// MARK: - Roles
enum Role: String, CaseIterable, Codable {
    case president = "President"
    case sccj = "Supreme Court Chief Justice"
    case treasury = "Head: Treasury"
    case labor = "Head: Labor"
    case education = "Head: Education"
    case construction = "Head: Construction"
    case transportation = "Head: Transportation"
    case publicHealth = "Head: Public Health"
    case agriculture = "Head: Agriculture"
    case resource = "Head: Resource Allocation"

    var id: String { rawValue }

    var isHead: Bool {
        switch self {
        case .president, .sccj: return false
        default: return true
        }
    }
}


// MARK: - Player
struct Player: Identifiable {
    let id = UUID()
    let index: Int
    var name: String
    var role: Role?
    var gold: Double
    var personalScore: Double = 0
}



// MARK: - Society
struct Society: Codable {
    // Population & workforce
    var population: Int = 0
    var uneducated: Int = 0
    var educated: Int = 0
    var highSkilled: Int = 0
    var researchers: Int = 0
    // Infrastructure
    var smallBuildings: Int = 0
    var bigBuildings: Int = 0
    var machinery: Int = 0

    func totalSocietyPoints() -> Int {
        let popPts = population * 5
        let unedPts = uneducated * 10
        let edPts = educated * 20
        let hsPts = highSkilled * 30
        let rPts = researchers * 30
        let sbPts = smallBuildings * 200
        let bbPts = bigBuildings * 400
        let machPts = machinery * 400
        return popPts + unedPts + edPts + hsPts + rPts + sbPts + bbPts + machPts
    }
}

// MARK: - Campaigning Messages
struct ChatMessage: Identifiable, Codable, Hashable {
    let id = UUID()
    let fromIndex: Int
    let toIndex: Int?   // nil => rally (to everyone)
    let text: String
    let isRally: Bool
    let round: Int
}

// MARK: - Promise
struct Promise: Identifiable, Codable, Hashable {
    var turnsUntilPayment: Int?
    let id = UUID()
    let proposer: Int        // index of proposer
    let recipient: Int       // index of recipient
    let offer: String        // what proposer gives
    let consideration: String // what recipient must give
    var status: Status       // awaiting, accepted, rejected
    
    enum Status: String, Codable {
        case awaiting
        case accepted
        case rejected
    }
}
