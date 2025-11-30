//
//  Society_GameState.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/19/25.
//

import SwiftUI

// MARK: - GameState
/// Controls global state: campaigning, elections, player turns, and global progression.
/// World simulation handled externally via TurnEngine (InGameManager).
final class GameState: ObservableObject {
    // Fixed clockwise role order (matches your circle)
    let roleOrder: [Role] = [
        .president, .sccj, .treasury, .labor, .education,
        .construction, .transportation, .publicHealth,
        .agriculture, .resource
    ]

    // Indices of players in the above role order, and a pointer
    @Published private(set) var roleTurnOrderIndices: [Int] = []
    @Published private(set) var roleTurnPos: Int = 0
    // MARK: - Presidential Powers
    @Published var executiveOrders: [ExecutiveOrder] = []
    @Published var vetoRecords: [VetoRecord] = []
    struct ExecutiveOrder: Identifiable {
        let id = UUID()
        let description: String
        let proposedTurn: Int
        let effectiveTurn: Int
        var cancelled: Bool = false
    }

    struct VetoRecord: Identifiable {
        let id = UUID()
        let turn: Int
        let reason: String
    }

    /// Rebuilds the turn order from roles and sets currentIndex to President.
    /// Rebuilds the turn order from roles and sets currentIndex to President.
    func rebuildRoleTurnOrder() {
        var order: [Int] = []
        for role in roleOrder {
            if let idx = players.firstIndex(where: { $0.role == role }) {
                order.append(idx)
            }
        }

        // Only fallback if no roles at all
        if order.isEmpty {
            order = Array(players.indices)
        }

        roleTurnOrderIndices = order
        roleTurnPos = 0

        if let presIndex = players.firstIndex(where: { $0.role == .president }) {
            currentIndex = presIndex
        } else if let first = roleTurnOrderIndices.first {
            currentIndex = first
        } else {
            currentIndex = 0
        }
    }
    



    // MARK: - Voting
    @Published var votingPhase: VotingPhase = .nominations
    @Published var declarations: [CandidateDeclaration] = []
    @Published var votes: [Vote] = []
    @Published var revotePositions: [Role: [Int]] = [:]
    @Published var governmentProjects: [GovernmentProject] = []

    

    // MARK: - Stage and Players
    @Published var stage: Stage = .campaigning {
        didSet {
            // When the game enters the running stage, fix starting order
            if stage == .running {
                rebuildRoleTurnOrder()
                roleTurnPos = 0
                if let presIndex = players.firstIndex(where: { $0.role == .president }) {
                    currentIndex = presIndex
                } else if let first = roleTurnOrderIndices.first {
                    currentIndex = first
                } else {
                    currentIndex = 0
                }
                print("🟣 Stage changed to running — starting with \(players[currentIndex].role?.rawValue ?? "nil")")
            }
        }
    }


    @Published var currentIndex: Int = 0
    @Published var turnNumber: Int = 1
    let maxRounds: Int = 50

    // Reference to in-game simulation controller
    weak var turnEngine: TurnEngine?

    // Society tracking (for scoring)
    @Published var society = Society()

    // MARK: - Campaigning
    @Published var campaignRound: Int = 1
    let maxCampaignRounds: Int = 5
    @Published var messages: [ChatMessage] = []
    @Published var campaignSecondsRemaining: Int = 30 * 60

    // MARK: - Computed
    @Published var players: [Player] = (0..<10).map { i in
        Player(index: i, name: "Player \(i+1)", role: nil, gold: 100)
    }
    var currentPlayer: Player { players[currentIndex] }

    // MARK: - Turn Flow (Core)
    /// Advances to the next player using the fixed role order. When it wraps, advance the world.
    // MARK: - Turn Flow (Core)
    func endTurn() {
        // 🔑 Build role order on first use (roles must already be assigned)
        if roleTurnOrderIndices.isEmpty {
            rebuildRoleTurnOrder()
        }

        print("🟢 Turn order: \(roleTurnOrderIndices.map { players[$0].role?.rawValue ?? "nil" })")
        print("🟢 Current before endTurn: \(players[currentIndex].role?.rawValue ?? "nil")")

        // Move to next role slot (wrap = new round)
        if roleTurnOrderIndices.isEmpty {
            // safety fallback if somehow still empty
            currentIndex = min(currentIndex + 1, players.count - 1)
            return
        }

        if roleTurnPos >= roleTurnOrderIndices.count - 1 {
            // wrap -> new round
            roleTurnPos = 0

            turnEngine?.advanceWorldForNewRound()
            processScheduledPayments()

            turnNumber += 1
            if turnNumber > maxRounds { finishGame(); return }
        } else {
            roleTurnPos += 1
        }

        currentIndex = roleTurnOrderIndices[roleTurnPos]
    }




    private func processScheduledPayments() {
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
    }

    // MARK: - Voting Flow
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
            default:
                break
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

        for (pos, winners) in assignments {
            if let w = winners.first, players.indices.contains(w) {
                players[w].role = pos
            }
        }

        assignUnfilledRoles()

        // 🟡 Ensure the turn order starts from President
        rebuildRoleTurnOrder()
        if let presIndex = players.firstIndex(where: { $0.role == .president }) {
            currentIndex = presIndex
            roleTurnPos = 0
        } else {
            currentIndex = 0
        }

        votingPhase = .revealAssignments
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
                } else {
                    votingPhase = .revealAssignments
                }
                currentIndex = 0
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

    // MARK: - Campaign Helpers
    func inbox(for index: Int) -> [ChatMessage] {
        messages.filter { ($0.toIndex == index || $0.isRally) && $0.fromIndex != index }
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

    // MARK: - Role Assignment
    func quickAssignRolesRandomly() {
        var roles = Role.allCases
        roles.shuffle()
        
        // Assign random roles
        for i in players.indices {
            players[i].role = roles[i]
        }

        assignUnfilledRoles()

        // 🟩 Build role order AFTER roles are assigned
        rebuildRoleTurnOrder()

        // 🟩 Force President to start immediately
        if let presIndex = players.firstIndex(where: { $0.role == .president }) {
            currentIndex = presIndex
            roleTurnPos = 0
        } else {
            currentIndex = 0
        }

        // 🟩 Run this *before* any View renders (important)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }

        print("✅ Final role order: \(players.map { $0.role?.rawValue ?? "nil" })")
        print("✅ Turn order indices: \(roleTurnOrderIndices.map { players[$0].role?.rawValue ?? "nil" })")
        print("✅ Starting with: \(players[currentIndex].role?.rawValue ?? "nil")")

        stage = .running
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

    // MARK: - Gold Management
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

    // MARK: - Promise Handling
    @Published var promises: [Promise] = []
    @Published var lockedVotes: [Int: (Role, Int)] = [:]
    @Published var scheduledPayments: [DelayedPayment] = []

    func proposePromise(to recipientIndex: Int, gold: Int, position: Role) {
        guard canAfford(1) else { return }
        players[currentIndex].gold -= 1
        let offer = "\(gold) gold after 3 rounds"
        let consideration = "Vote for me for \(position.rawValue)"
        let newPromise = Promise(proposer: currentIndex, recipient: recipientIndex, offer: offer, consideration: consideration, status: .awaiting)
        promises.append(newPromise)
    }

    func acceptPromise(_ id: UUID) {
        guard let idx = promises.firstIndex(where: { $0.id == id }) else { return }
        promises[idx].status = .accepted
        let p = promises[idx]

        if p.consideration.contains("Vote for me for") {
            if let role = Role.allCases.first(where: { p.consideration.contains($0.rawValue) }) {
                lockedVotes[p.recipient] = (role, p.proposer)
            }
        }

        scheduledPayments.append(
            DelayedPayment(from: p.proposer, to: p.recipient,
                           amount: Double(p.offer.split(separator: " ").first ?? "0") ?? 0,
                           turnsRemaining: 2)
        )
    }

    func rejectPromise(_ id: UUID) {
        promises.removeAll { $0.id == id }
    }

    // MARK: - Finish / Reset
    func finishGame() {
        let total = Double(society.totalSocietyPoints())
        for i in players.indices {
            let role = players[i].role
            let weight: Double = (role == .president) ? 0.14 : (role == .sccj ? 0.12 : 0.09)
            let roleShare = weight * total
            let goldBonus = 10.0 * players[i].gold
            players[i].personalScore = roleShare + goldBonus
        }
        stage = .ended
    }

    func resetGame() {
        stage = .campaigning
        players = (0..<10).map { i in
            Player(index: i, name: "Player \(i+1)", role: nil, gold: 100)
        }
        currentIndex = 0
        turnNumber = 1
        society = Society()
        campaignSecondsRemaining = 30 * 60
        promises.removeAll()
        votes.removeAll()
        declarations.removeAll()
    }
    // MARK: - Presidential Actions API

    /// Broadcasts a cheaper rally that only the President can do (2 gold).
    func sendPresidentialSpeech(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard players[currentIndex].role == .president else { return }

        let cost: Double = 2.0
        guard canAfford(cost) else { return }
        spend(cost)

        messages.append(
            ChatMessage(
                fromIndex: currentIndex,
                toIndex: nil,
                text: "PRESIDENTIAL SPEECH: \(trimmed)",
                isRally: true,
                round: campaignRound      // reuse campaignRound for now
            )
        )
    }

    /// Queues an Executive Order that will take effect in 2 turns (game logic TBD).
    func issueExecutiveOrder(description: String) {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard players[currentIndex].role == .president else { return }

        let cost: Double = 5.0
        guard canAfford(cost) else { return }
        spend(cost)

        let eo = ExecutiveOrder(
            description: trimmed,
            proposedTurn: turnNumber,
            effectiveTurn: turnNumber + 2
        )
        executiveOrders.append(eo)

        print("🛑 Executive Order queued: \(trimmed) – will be effective on turn \(eo.effectiveTurn)")
    }
    // Active projects that can be vetoed *this* turn
    var vetoableProjects: [GovernmentProject] {
        governmentProjects.filter { proj in
            proj.status == .proposed || proj.status == .inProgress
        }
    }

    /// Apply a presidential veto to a project
    func applyPresidentialVeto(to projectID: UUID) {
        guard let idx = governmentProjects.firstIndex(where: { $0.id == projectID }) else { return }

        governmentProjects[idx].status = .cancelledByVeto

        // Optional: refund resources / undo effects here
        // e.g. reclaim raw materials, cancel scheduled payments, etc.
    }


    /// Records a Veto use (actual project-overriding logic can hook into this later).
    func useVeto(reason: String) {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard players[currentIndex].role == .president else { return }

        let veto = VetoRecord(turn: turnNumber, reason: trimmed)
        vetoRecords.append(veto)

        print("🧾 VETO used on turn \(turnNumber): \(trimmed)")
    }


    
    // MARK: - Supporting Types
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

    struct DelayedPayment: Identifiable {
        let id = UUID()
        let from: Int
        let to: Int
        let amount: Double
        var turnsRemaining: Int
    }
}

// MARK: - Government Projects

enum GovernmentProjectStatus: String, Codable {
    case proposed
    case inProgress
    case completed
    case cancelledByVeto
}

struct GovernmentProject: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String            // e.g. "Build Hospital"
    var department: Role        // which role owns it (President, Treasury, etc.)
    var description: String
    var status: GovernmentProjectStatus
    var turnStarted: Int

    init(
        name: String,
        department: Role,
        description: String,
        status: GovernmentProjectStatus,
        turnStarted: Int
    ) {
        self.id = UUID()
        self.name = name
        self.department = department
        self.description = description
        self.status = status
        self.turnStarted = turnStarted
    }
}
