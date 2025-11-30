//
//  InGameManager.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/19/25.
//

import Foundation
import SwiftUI

// ------------------------------------------------------------
// MARK: - Department Approvers
// ------------------------------------------------------------
enum ApprovingDepartment {
    case education
    case resource
    case publicHealth
    case transportation
    case treasury
}

// ------------------------------------------------------------
// MARK: - Turn Engine Protocol
// ------------------------------------------------------------
protocol TurnEngine: AnyObject {
    func advanceWorldForNewRound()
}

// ------------------------------------------------------------
// MARK: - InGameManager
// ------------------------------------------------------------
@MainActor
final class InGameManager: ObservableObject, TurnEngine {

    let game: GameState

    // --------------------------------------------------------
    // MARK: - Published World State
    // --------------------------------------------------------
    @Published var society: SocietyInGame = .baseGame()
    @Published var rawMaterials: Int = 10
    @Published var constructionQueue: [BuildingProject] = []

    @Published var pendingApproval: ProposedBuilding? = nil

    init(game: GameState) {
        self.game = game
        game.turnEngine = self
    }
    
    func addProject(_ project: BuildingProject) {
        constructionQueue.append(project)
    }


    var players: [Player] { game.players }

    // --------------------------------------------------------
    // MARK: - Turn Engine
    // --------------------------------------------------------
    func advanceWorldForNewRound() {
        progressPopulation()
        progressFood()
        progressProjects()
        produceResources()
        removeDeadPopulation()
    }

    let turnOrder: [Role] = [
        .president, .sccj, .treasury, .labor, .education,
        .construction, .transportation, .publicHealth,
        .agriculture, .resource
    ]

    // --------------------------------------------------------
    // MARK: - POPULATION
    // --------------------------------------------------------
    private func progressPopulation() {
        for i in society.population.indices {
            society.population[i].progressHealth()
        }
    }

    private func removeDeadPopulation() {
        society.population.removeAll { $0.isDead }
    }

    // --------------------------------------------------------
    // MARK: - FOOD
    // --------------------------------------------------------
    private func progressFood() {
        for i in society.foodStorage.indices {
            society.foodStorage[i].progressTurn()
        }

        society.foodStorage.removeAll { $0.isConsumed }

        let need = society.population.count
        if society.foodStorage.count >= need {
            society.foodStorage.removeFirst(need)
        } else {
            let deficit = need - society.foodStorage.count
            for i in 0..<min(deficit, society.population.count) {
                society.population[i].hungeredTurns += 1
            }
            society.foodStorage.removeAll()
        }
    }

    // --------------------------------------------------------
    // MARK: - Building ENUM (INSIDE CLASS)
    // --------------------------------------------------------
    enum Building: String, CaseIterable, Codable, Identifiable {
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
            let isBig: Bool
        }

        var requirements: Requirements {
            switch self {
            case .mine:
                return .init(workers: 10, gold: 5, rawMaterials: 0, isBig: false)
            case .goldMine:
                return .init(workers: 10, gold: 0, rawMaterials: 5, isBig: true)
            case .school:
                return .init(workers: 10, gold: 0, rawMaterials: 5, isBig: false)
            case .college:
                return .init(workers: 10, gold: 0, rawMaterials: 10, isBig: true)
            case .clinic:
                return .init(workers: 10, gold: 0, rawMaterials: 5, isBig: false)
            case .hospital:
                return .init(workers: 10, gold: 0, rawMaterials: 10, isBig: true)
            case .federalBank:
                return .init(workers: 10, gold: 10, rawMaterials: 10, isBig: true)
            }
        }

        var approver: ApprovingDepartment {
            switch self {
            case .mine, .goldMine:
                return .resource
            case .school, .college:
                return .education
            case .clinic, .hospital:
                return .publicHealth
            case .federalBank:
                return .treasury
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - REQUEST BUILDING (Construction Dept)
    // --------------------------------------------------------
    func requestBuilding(_ b: Building, by p: Player) {
        pendingApproval = ProposedBuilding(building: b, requestedBy: p)
    }

    // --------------------------------------------------------
    // MARK: - CHECK IF PLAYER CAN APPROVE
    // --------------------------------------------------------
    func playerCanApprove(_ player: Player) -> Bool {
        guard let pending = pendingApproval else { return false }

        switch pending.building.approver {
        case .education:
            return player.role == .education
        case .resource:
            return player.role == .resource
        case .publicHealth:
            return player.role == .publicHealth
        case .transportation:
            return player.role == .transportation
        case .treasury:
            return player.role == .treasury
        }
    }

    // --------------------------------------------------------
    // MARK: - APPROVE / DENY BUILDING
    // --------------------------------------------------------
    func approvePendingBuilding() {
        guard let proposal = pendingApproval else { return }
        let req = proposal.building.requirements

        // 1. CHECK WORKERS
        let uneducated = society.population.filter { $0.isUneducatedLabor }.count
        guard uneducated >= req.workers else { return }
        removeUneducatedWorkers(req.workers)

        // 2. CONSTRUCTION PAYS GOLD
        guard let cIndex = game.players.firstIndex(where: { $0.role == .construction }) else { return }
        guard game.players[cIndex].gold >= Double(req.gold) else { return }
        game.players[cIndex].gold -= Double(req.gold)

        // 3. RAW MATERIALS
        guard rawMaterials >= req.rawMaterials else { return }
        rawMaterials -= req.rawMaterials

        // 4. CONSTRUCTION QUEUE
        let projectType: BuildingProject.BuildingType =
            req.isBig ? .bigBuilding : .smallBuilding

        constructionQueue.append(
            BuildingProject(
                type: projectType,
                turnsRemaining: req.isBig ? 3 : 2,
                initiatedBy: proposal.requestedBy.id.uuidString
            )
        )
        if let i = game.players.firstIndex(where: { $0.role == .construction }) {
            game.players[i].gold -= Double(req.gold)
        }


        pendingApproval = nil
    }

    func denyPendingBuilding() {
        pendingApproval = nil
    }

    // --------------------------------------------------------
    // MARK: - Worker Removal
    // --------------------------------------------------------
    private func removeUneducatedWorkers(_ count: Int) {
        var needed = count
        for i in society.population.indices {
            if society.population[i].isUneducatedLabor && needed > 0 {
                society.population[i].isEducatedLabor = true
                needed -= 1
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - PROJECT PROGRESS
    // --------------------------------------------------------
    private func progressProjects() {
        for i in constructionQueue.indices {
            constructionQueue[i].turnsRemaining -= 1
        }

        constructionQueue.removeAll { project in
            if project.turnsRemaining <= 0 {
                switch project.type {
                case .smallBuilding: society.smallBuildings += 1
                case .bigBuilding:   society.bigBuildings += 1
                case .machinery:     society.machinery += 1
                }
                return true
            }
            return false
        }
    }

    // --------------------------------------------------------
    // MARK: - Production
    // --------------------------------------------------------
    private func produceResources() {
        let uneducated = society.population.filter { $0.isUneducatedLabor }.count

        let producedFood = 2 * uneducated
        for _ in 0..<producedFood {
            society.foodStorage.append(Food())
        }

        let ore = uneducated / 10
        rawMaterials += ore
    }

    // --------------------------------------------------------
    // MARK: - Metrics
    // --------------------------------------------------------
    func societyPoints() -> Int { society.totalSocietyPoints }

    func foodBreakdown() -> FoodStorage {
        FoodStorage.from(foodArray: society.foodStorage)
    }

    // --------------------------------------------------------
    // MARK: - Advance Turn
    // --------------------------------------------------------
    func advanceTurn() {
        game.endTurn()
    }
}

// ------------------------------------------------------------
// MARK: - Proposed Building (OUTSIDE CLASS)
// ------------------------------------------------------------
struct ProposedBuilding: Identifiable {
    let id = UUID()
    let building: InGameManager.Building
    let requestedBy: Player
}

// ------------------------------------------------------------
// MARK: - Building Project (EXISTING)
// ------------------------------------------------------------
struct BuildingProject: Identifiable, Codable {
    let id = UUID()
    var type: BuildingType
    var turnsRemaining: Int
    var initiatedBy: String

    enum BuildingType: String, Codable {
        case smallBuilding
        case bigBuilding
        case machinery
    }
}

extension Society {
    func currentRole(for player: Player) -> Role? { player.role }
}
