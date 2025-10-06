//
//  Society_Constants.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import Foundation

// MARK: - Game Stages
enum Stage: String, Codable, CaseIterable {
    case campaigning = "Campaigning"
    case voting = "Voting"
    case running = "Running"
    case ended = "Ended"
}

// MARK: - Roles
enum Role: String, Codable, CaseIterable, Identifiable {
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
