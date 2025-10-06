//
//  Society_Variables.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import Foundation
import SwiftUI

// MARK: - Player
struct Player: Identifiable, Codable, Hashable {
    let id = UUID()
    let index: Int        // <— add this
    var name: String
    var gold: Double = 100
    var role: Role? = nil
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

// MARK: - Game State
final class GameState: ObservableObject {
    // Voting
    @Published var votingPhase: VotingPhase = .nominations
    @Published var declarations: [CandidateDeclaration] = []
    @Published var votes: [Vote] = []
    @Published var revotePositions: [Role: [Int]] = [:] // role → tied candidate indices

    // Stage and players
    @Published var stage: Stage = .campaigning
    @Published var players: [Player] = (0..<10).map { i in
        Player(index: i, name: "Player \(i+1)")
    }
    @Published var currentIndex: Int = 0
    @Published var turnNumber: Int = 1
    @Published var society = Society()

    // Campaigning
    @Published var campaignRound: Int = 1
    let maxCampaignRounds: Int = 5
    @Published var messages: [ChatMessage] = []
    @Published var campaignSecondsRemaining: Int = 30 * 60

    // Computed
    var currentPlayer: Player { players[currentIndex] }

    // MARK: Voting flow
    func nextVotingPlayer() {
        if currentIndex == players.count - 1 {
            currentIndex = 0
            switch votingPhase {
            case .nominations:
                votingPhase = .voting
                votes.removeAll()
            case .voting:
                computeResults()
            case .revote(let pos):
                computeRevote(for: pos)
            default: break
            }
        } else {
            currentIndex += 1
        }
    }

    func computeResults() {
        var assignments: [Role: [Int]] = [:]
        var ties: [Role: [Int]] = [:]

        for pos in Role.allCases {
            let posVotes = votes.filter { $0.position == pos }
            var counts: [Int: Int] = [:]
            for v in posVotes {
                for c in v.chosen {
                    counts[c, default: 0] += 1
                }
            }
            if let maxCount = counts.values.max() {
                let winners = counts.filter { $0.value == maxCount }.map { $0.key }
                if winners.count == 1 {
                    assignments[pos] = winners
                } else {
                    ties[pos] = winners
                }
            }
        }
        for (voter, locked) in lockedVotes {
            votes.append(Vote(voterIndex: voter, position: locked.0, chosen: [locked.1]))
        }

        if !ties.isEmpty {
            revotePositions = ties
            votingPhase = .revote(position: ties.keys.first!)
            currentIndex = 0
            return
        }

        // Step A: assign all clear winners
        for (pos, winners) in assignments {
            if let w = winners.first {
                players[w].role = pos
            }
        }

        // ✅ Step B: assign leftover roles randomly
        var unassignedRoles = Set(Role.allCases)
        for p in players {
            if let r = p.role {
                unassignedRoles.remove(r)
            }
        }
        var unassignedPlayers = players.indices.filter { players[$0].role == nil }
        unassignedPlayers.shuffle()
        for (playerIndex, role) in zip(unassignedPlayers, unassignedRoles.shuffled()) {
            players[playerIndex].role = role
        }

        votingPhase = .revealAssignments
        currentIndex = 0
    }


    func computeRevote(for position: Role) {
        let posVotes = votes.filter { $0.position == position }
        var counts: [Int: Int] = [:]
        for v in posVotes {
            for c in v.chosen {
                counts[c, default: 0] += 1
            }
        }
        if let maxCount = counts.values.max() {
            let winners = counts.filter { $0.value == maxCount }.map { $0.key }
            if winners.count == 1 {
                players[winners.first!].role = position
                revotePositions.removeValue(forKey: position)
                if let next = revotePositions.keys.first {
                    votingPhase = .revote(position: next)
                    currentIndex = 0
                } else {
                    votingPhase = .revealAssignments
                    currentIndex = 0
                }
            } else {
                votingPhase = .revote(position: position)
                currentIndex = 0
            }
        }
    }

    func declareCandidacy(for positions: [Role]) {
        declarations.removeAll { $0.playerIndex == currentIndex }
        declarations.append(CandidateDeclaration(playerIndex: currentIndex, positions: positions))
        nextVotingPlayer()
    }

    func castVote(for position: Role, chosen: [Int]) {
        votes.removeAll { $0.voterIndex == currentIndex && $0.position == position }
        votes.append(Vote(voterIndex: currentIndex, position: position, chosen: chosen))
    }

    enum VotingPhase: Codable {
        case nominations
        case voting
        case revote(position: Role)
        case revealAssignments
        case finished
    }

    struct CandidateDeclaration: Identifiable, Codable {
        let id = UUID()
        let playerIndex: Int
        let positions: [Role]
    }

    struct Vote: Identifiable, Codable {
        let id = UUID()
        let voterIndex: Int
        let position: Role
        let chosen: [Int]
    }

    // MARK: Campaign helpers
    func inbox(for index: Int) -> [ChatMessage] {
        messages.filter { ( $0.toIndex == index || $0.isRally) && $0.fromIndex != index }
    }

    func conversation(between i: Int, and j: Int) -> [ChatMessage] {
        messages.filter { m in
            if m.isRally {
                return m.fromIndex == i || m.fromIndex == j
            } else {
                return (m.fromIndex == i && m.toIndex == j) || (m.fromIndex == j && m.toIndex == i)
            }
        }
    }

    func sendText(to index: Int, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let cost: Double = 1.0
        guard canAfford(cost) else { return }
        spend(cost)
        messages.append(ChatMessage(fromIndex: currentIndex, toIndex: index, text: text, isRally: false, round: campaignRound))
    }

    func sendRally(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let cost: Double = 5.0
        guard canAfford(cost) else { return }
        spend(cost)
        messages.append(ChatMessage(fromIndex: currentIndex, toIndex: nil, text: text, isRally: true, round: campaignRound))
    }

    func nextCampaignPlayer() {
        if currentIndex == players.count - 1 {
            currentIndex = 0
            campaignRound += 1
            if campaignRound > maxCampaignRounds {
                stage = .voting
            }
        } else {
            currentIndex += 1
        }
    }

    // MARK: Role assignment (simplified)
    func quickAssignRolesRandomly() {
        var roles: [Role] = [.president, .sccj, .treasury, .labor, .education, .construction, .transportation, .publicHealth, .agriculture, .resource]
        roles.shuffle()
        for i in players.indices {
            players[i].role = roles[i]
        }
        players.sort { a, b in
            switch (a.role, b.role) {
            case (.president?, .president?): return false
            case (.president?, _): return true
            case (_, .president?): return false
            case (.sccj?, .sccj?): return false
            case (.sccj?, _): return true
            case (_, .sccj?): return false
            default:
                return (a.role?.rawValue ?? "") < (b.role?.rawValue ?? "")
            }
        }
        currentIndex = 0
        stage = .running
    }

    // MARK: Gold & actions
    func canAfford(_ cost: Double) -> Bool {
        players[currentIndex].gold >= cost - 1e-9
    }

    func spend(_ amount: Double) {
        guard amount > 0 else { return }
        if players[currentIndex].gold >= amount {
            players[currentIndex].gold -= amount
        }
    }

    func earn(_ amount: Double) {
        guard amount > 0 else { return }
        players[currentIndex].gold += amount
    }

    func communication() {
        let role = players[currentIndex].role
        let cost: Double = (role == .president || role == .transportation) ? 0.5 : 1.0
        spend(cost)
    }

    func rally() {
        let role = players[currentIndex].role
        let cost: Double = (role == .president) ? 2.0 : 5.0
        spend(cost)
    }

    // MARK: Society counters
    func addPopulation(_ n: Int) { society.population = max(0, society.population + n) }
    func addUneducated(_ n: Int) { society.uneducated = max(0, society.uneducated + n) }
    func addEducated(_ n: Int) { society.educated = max(0, society.educated + n) }
    func addHighSkilled(_ n: Int) { society.highSkilled = max(0, society.highSkilled + n) }
    func addResearchers(_ n: Int) { society.researchers = max(0, society.researchers + n) }
    func addSmallBuilding(_ n: Int) { society.smallBuildings = max(0, society.smallBuildings + n) }
    func addBigBuilding(_ n: Int) { society.bigBuildings = max(0, society.bigBuildings + n) }
    func addMachinery(_ n: Int) { society.machinery = max(0, society.machinery + n) }

    // MARK: Turn flow
    func endTurn() {
        let wasLast = currentIndex == players.count - 1
        if wasLast {
            currentIndex = 0
            turnNumber += 1

            //  — Process delayed payments
            for i in scheduledPayments.indices.reversed() {
                scheduledPayments[i].turnsRemaining -= 1
                if scheduledPayments[i].turnsRemaining <= 0 {
                    let p = scheduledPayments[i]
                    if players[p.from].gold >= p.amount {
                        players[p.from].gold -= p.amount
                        players[p.to].gold += p.amount
                    }
                    scheduledPayments.remove(at: i)
                }
            }

            if turnNumber > 10 {
                finishGame()
                return
            }
        } else {
            currentIndex += 1
        }
    }


    func finishGame() {
        let total = Double(society.totalSocietyPoints())
        for i in players.indices {
            let role = players[i].role
            let weight: Double
            switch role {
            case .president?: weight = 0.14
            case .sccj?: weight = 0.12
            default: weight = 0.09
            }
            let roleShare = weight * total
            let goldBonus = 10.0 * players[i].gold
            players[i].personalScore = roleShare + goldBonus
        }
        stage = .ended
    }

    func resetGame() {
        stage = .campaigning
        players = (0..<10).map { i in
            Player(index: i, name: "Player \(i+1)")
        }
        currentIndex = 0
        turnNumber = 1
        society = Society()
        campaignSecondsRemaining = 30 * 60
    }
    
    func assignUnfilledRoles() {
        var taken = Set(players.compactMap { $0.role })
        var available = Role.allCases.filter { !taken.contains($0) }
        available.shuffle()

        for i in players.indices where players[i].role == nil {
            if let nextRole = available.popLast() {
                players[i].role = nextRole
            }
        }
    }
    @Published var promises: [Promise] = []

    func proposePromise(to recipientIndex: Int, gold: Int, position: Role) {
        guard canAfford(1) else { return } // cost to propose
        players[currentIndex].gold -= 1

        let offer = "\(gold) gold after 3 rounds"
        let consideration = "Vote for me for \(position.rawValue)"

        let newPromise = Promise(
            proposer: currentIndex,
            recipient: recipientIndex,
            offer: offer,
            consideration: consideration,
            status: .awaiting
        )

        promises.append(newPromise)
    }


    func acceptPromise(_ promiseID: UUID) {
        guard let idx = promises.firstIndex(where: { $0.id == promiseID }) else { return }
        promises[idx].status = .accepted
        
        let promise = promises[idx]
        
        // If this is a vote-type promise, mark the recipient's locked vote
        if promise.consideration.contains("Vote for me for") {
            if let role = Role.allCases.first(where: { promise.consideration.contains($0.rawValue) }) {
                lockedVotes[promise.recipient] = (role, promise.proposer)
            }
        }
        
        // Schedule gold deduction after 2 turns
        scheduledPayments.append(DelayedPayment(
            from: promise.proposer,
            to: promise.recipient,
            amount: Double(promise.offer.components(separatedBy: " ").first ?? "0") ?? 0,
            turnsRemaining: 2
        ))
    }


    func rejectPromise(_ promiseID: UUID) {
        promises.removeAll { $0.id == promiseID }
    }
    
    @Published var lockedVotes: [Int: (Role, Int)] = [:] // recipient → (role, candidate)
    @Published var scheduledPayments: [DelayedPayment] = []

    struct DelayedPayment: Identifiable {
        let id = UUID()
        let from: Int
        let to: Int
        let amount: Double
        var turnsRemaining: Int
    }


}

