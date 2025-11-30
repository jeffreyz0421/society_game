//
//  In_Game_Def.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/19/25.
//

import Foundation
import SwiftUI

// MARK: - Global Society Definition
struct SocietyInGame: Codable {
    var population: [Population] = []
    var children: [ChildPopulation] = []
    var foodStorage: [Food] = []
    var rawMaterials: Int = 10

    // Infrastructure
    var smallBuildings: Int = 0
    var bigBuildings: Int = 0
    var machinery: Int = 0

    // Derived Metrics
    var totalFood: Int { foodStorage.count }
    var totalSocietyPoints: Int {
        let popPts = population.count * 5
        let unedPts = population.filter { $0.isUneducatedLabor }.count * 10
        let edPts = population.filter { $0.isEducatedLabor }.count * 20
        let hsPts = population.filter { $0.isHighSkill }.count * 30
        let rPts = population.filter { $0.isResearcher }.count * 40
        let sbPts = smallBuildings * 200
        let bbPts = bigBuildings * 400
        let machPts = machinery * 400
        return popPts + unedPts + edPts + hsPts + rPts + sbPts + bbPts + machPts
    }

    // Base initializer
    static func baseGame() -> SocietyInGame {
        let population = (0..<100).map { _ in Population() }
        let foodStorage = (0..<100).map { _ in Food() }
        return SocietyInGame(population: population, children: [], foodStorage: foodStorage, rawMaterials: 10)
    }
}

//
// MARK: - Population
//
struct Population: Identifiable, Codable {
    let id = UUID()
    var foodConsumption: Int = 1

    // Education levels
    var isEducatedLabor: Bool = false
    var isHighSkill: Bool = false
    var isResearcher: Bool = false
    var isUneducatedLabor: Bool { !isEducatedLabor && !isHighSkill && !isResearcher }

    // Health
    var hungeredTurns: Int = 0
    var isDead: Bool = false

    // Illness states
    var sicknessLevel: Int = 0 // 0 = healthy, 1–5 = increasing severity

    // Helpers for filtering
    var isSickLevel1: Bool { sicknessLevel == 1 }
    var isSickLevel2: Bool { sicknessLevel == 2 }
    var isSickLevel3: Bool { sicknessLevel == 3 }
    var isSickLevel4: Bool { sicknessLevel == 4 }
    var isSickLevel5: Bool { sicknessLevel == 5 }

    // Health progression
    mutating func progressHealth() {
        if sicknessLevel > 0 { sicknessLevel += 1 }
        if sicknessLevel > 5 { isDead = true }
        if hungeredTurns >= 2 { isDead = true }
    }
}

//
// MARK: - Children
//
struct ChildPopulation: Identifiable, Codable {
    let id = UUID()
    var currentlyInSchool: Bool = false
    var wentToSchool: Bool = false

    func graduate() -> Population {
        if wentToSchool {
            return Population(isEducatedLabor: true)
        } else {
            return Population(isEducatedLabor: false)
        }
    }
}

//
// MARK: - Food
//
struct Food: Codable, Identifiable {
    let id = UUID()
    var isConsumed: Bool = false
    var turnsOld: Int = 0
    let maxSpoilTurns: Int = 4 // spoils after 4 turns

    var isSpoiled: Bool {
        turnsOld >= maxSpoilTurns
    }

    mutating func progressTurn() {
        if !isConsumed { turnsOld += 1 }
    }
}

//
// MARK: - Food Storage Breakdown
//
struct FoodStorage: Codable {
    var foods: [Food]

    var freshCount: Int {
        foods.filter { !$0.isConsumed && !$0.isSpoiled && $0.turnsOld == 0 }.count
    }

    var spoilingCount: Int {
        foods.filter { !$0.isConsumed && !$0.isSpoiled && $0.turnsOld > 0 && $0.turnsOld < $0.maxSpoilTurns }.count
    }

    var consumedCount: Int {
        foods.filter { $0.isConsumed || $0.isSpoiled }.count
    }

    static func from(foodArray: [Food]) -> FoodStorage {
        FoodStorage(foods: foodArray)
    }
}

//
// MARK: - Labor Types
//
struct UneducatedLabor: Codable { let productivity: Int = 1 }
struct EducatedLabor: Codable { let productivity: Int = 2 }
struct HighSkillLabor: Codable { let productivity: Int = 3 }


// MARK: - Building Types
enum BuildingType: String, CaseIterable, Identifiable {
    case mine = "Mine"
    case goldMine = "Gold Mine"
    case school = "School"
    case college = "College"
    case clinic = "Clinic"
    case hospital = "Hospital"
    case federalBank = "Federal Bank"
    
    var id: String { rawValue }
    
    struct Requirements {
        let workers: Int
        let gold: Int
        let rawMaterials: Int
        let needsApproval: Bool
    }
    
    var requirements: Requirements {
        switch self {
        case .mine:
            return .init(workers: 10, gold: 5, rawMaterials: 0, needsApproval: true)
        case .goldMine:
            return .init(workers: 10, gold: 0, rawMaterials: 5, needsApproval: true)
        case .school:
            return .init(workers: 10, gold: 0, rawMaterials: 5, needsApproval: true)
        case .college:
            return .init(workers: 10, gold: 0, rawMaterials: 10, needsApproval: true)
        case .clinic:
            return .init(workers: 10, gold: 0, rawMaterials: 5, needsApproval: true)
        case .hospital:
            return .init(workers: 10, gold: 0, rawMaterials: 10, needsApproval: true)
        case .federalBank:
            return .init(workers: 10, gold: 10, rawMaterials: 10, needsApproval: true)
        }
    }
}
