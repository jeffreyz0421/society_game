//
//  Society_Voting_Phase.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import SwiftUI

// MARK: - Voting View
struct VotingView: View {
    @ObservedObject var game: GameState
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Voting Phase: \(String(describing: game.votingPhase))")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .padding(.top, 10)

            // Subtitle
            switch game.votingPhase {
            case .nominations:
                Text("\(game.currentPlayer.name), declare up to 2 positions to run for.")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

            case .voting:
                Text("\(game.currentPlayer.name), cast your votes.")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

            case .revote(let pos):
                Text("\(game.currentPlayer.name), revote for \(pos.rawValue).")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

            case .finished:
                Text("Voting finished, roles assigned!")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

            case .revealAssignments:
                EmptyView()
            }

            // Phase-specific view
            switch game.votingPhase {
            case .nominations:
                VotingNominationsView(game: game)
            case .voting:
                VotingBallotView(game: game)
            case .revote(let pos):
                RevoteBallotView(game: game, position: pos)
            case .finished:
                Button("Start Running Stage") {
                    game.stage = .running
                }
                .buttonStyle(.borderedProminent)
            case .revealAssignments:
                AssignmentRevealView(game: game)
            }
        }
        .padding()
    }
}

// MARK: - Nominations
struct VotingNominationsView: View {
    @ObservedObject var game: GameState
    @State private var selectedRoles: Set<Role> = []
    
    let roleEmojis: [Role: String] = [
        .president: "🎩",
        .sccj: "⚖️",
        .treasury: "💰",
        .labor: "🛠️",
        .education: "📚",
        .construction: "🚧",
        .transportation: "🚌",
        .publicHealth: "🩺",
        .agriculture: "🌾",
        .resource: "📦"
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Choose up to 2 positions:")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                ForEach(Role.allCases, id: \.self) { role in
                    let isSelected = selectedRoles.contains(role)
                    Button(action: {
                        if isSelected {
                            selectedRoles.remove(role)
                        } else if selectedRoles.count < 2 {
                            selectedRoles.insert(role)
                        }
                    }) {
                        HStack {
                            Text(roleEmojis[role] ?? "❓")
                                .font(.system(size: 22))
                            Text(role.rawValue)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? Color.blue.opacity(0.2) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 10)
            
            Button("✅ Confirm Declaration") {
                let chosen = Array(selectedRoles.prefix(2))
                game.declareCandidacy(for: chosen)
                selectedRoles.removeAll()
            }
            .disabled(selectedRoles.isEmpty)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(selectedRoles.isEmpty ? Color.gray.opacity(0.4) : Color.green.opacity(0.8))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 12)
        }
        .padding()
    }
}

// MARK: - Ballot Voting
struct VotingBallotView: View {
    @ObservedObject var game: GameState
    @State private var choices: [Role: Int] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 10) {
                    ForEach(Role.allCases, id: \.self) { role in
                        
                        // 🔒 Check if this player's vote is locked by a promise
                        if let locked = game.lockedVotes[game.currentIndex], locked.0 == role {
                            let candidate = game.players[locked.1]
                            VStack(spacing: 8) {
                                Text("🎩 \(role.rawValue)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Promised to vote for \(candidate.name)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(colors: [Color.yellow.opacity(0.3),
                                                                Color.orange.opacity(0.15)],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                Text("🗳️ Vote locked by promise")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.orange)
                                    .italic()
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .gray.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                        } else {
                            // 🗳️ Regular interactive voting card
                            let candidates: [Player] = game.declarations
                                .filter { $0.positions.contains(role) }
                                .compactMap { decl in
                                    game.players[decl.playerIndex]
                                }
                            
                            if !candidates.isEmpty {
                                VotingRoleCard(
                                    role: role,
                                    candidates: candidates,
                                    selected: Binding(
                                        get: { choices[role] ?? -1 },
                                        set: { choices[role] = $0 }
                                    )
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                
                // ✅ Submit button
                Button("🗳️ Submit Votes") {
                    // Include locked votes automatically
                    for (voter, locked) in game.lockedVotes where voter == game.currentIndex {
                        game.castVote(for: locked.0, chosen: [locked.1])
                    }
                    // Add any manual choices
                    for (pos, candidateIndex) in choices where candidateIndex != -1 {
                        game.castVote(for: pos, chosen: [candidateIndex])
                    }
                    choices.removeAll()
                    game.nextVotingPlayer()
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 10)
            }
            .padding(.vertical, 6)
        }
    }
}


// MARK: - Cute Role Card
struct VotingRoleCard: View {
    let role: Role
    let candidates: [Player]
    @Binding var selected: Int
    
    let roleEmojis: [Role: String] = [
        .president: "🎩",
        .sccj: "⚖️",
        .treasury: "💰",
        .labor: "🛠️",
        .education: "📚",
        .construction: "🚧",
        .transportation: "🚌",
        .publicHealth: "🩺",
        .agriculture: "🌾",
        .resource: "📦"
    ]
    
    var body: some View {
        VStack(spacing: 4) {
            // Card title
            Text("\(roleEmojis[role] ?? "❓") \(role.rawValue)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.top, 2)
            
            Divider()
            
            // Candidate preview avatars
            HStack(spacing: 6) {
                ForEach(candidates) { player in
                    VStack(spacing: 1) {
                        Text(playerAvatars[player.index % playerAvatars.count])
                            .font(.system(size: 20))
                        Text(player.name)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 3)
            
            // Dropdown
            Menu {
                Button("Skip") { selected = -1 }
                ForEach(candidates) { player in
                    Button {
                        selected = player.index
                    } label: {
                        // ✅ Single Text string with both emoji + name
                        Text("\(playerAvatars[player.index % playerAvatars.count]) \(player.name)")
                    }
                }
            } label: {
                HStack {
                    if selected == -1 {
                        Text("Choose a candidate")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    } else if let candidate = candidates.first(where: { $0.index == selected }) {
                        // ✅ Collapsed menu also shows emoji + name
                        Text("\(playerAvatars[candidate.index % playerAvatars.count]) \(candidate.name)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.bottom, 4)

        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .gray.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}



// MARK: - Revote
struct RevoteBallotView: View {
    @ObservedObject var game: GameState
    let position: Role
    @State private var choice: Int = -1

    var body: some View {
        VStack {
            Text("\(game.currentPlayer.name), revote for \(position.rawValue).")
                .font(.headline)

            let tiedCandidates = game.revotePositions[position] ?? []
            if !tiedCandidates.isEmpty {
                Picker("Choose candidate", selection: $choice) {
                    Text("Skip").tag(-1)
                    ForEach(tiedCandidates, id: \.self) { idx in
                        Text(game.players[idx].name).tag(idx)
                        Text(game.players[idx].name)
                    }
                }
                .pickerStyle(.menu)
            }

            Button("Submit Revote") {
                if choice != -1 {
                    game.castVote(for: position, chosen: [choice])
                }
                choice = -1
                game.nextVotingPlayer()
            }
            .padding(.top, 12)
        }
        .padding()
    }
}

// MARK: - Assignment Reveal
struct AssignmentRevealView: View {
    @ObservedObject var game: GameState
    
    // reuse role emojis
    let roleEmojis: [Role: String] = [
        .president: "🎩",
        .sccj: "⚖️",
        .treasury: "💰",
        .labor: "🛠️",
        .education: "📚",
        .construction: "🚧",
        .transportation: "🚌",
        .publicHealth: "🩺",
        .agriculture: "🌾",
        .resource: "📦"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.96, green: 0.91, blue: 0.76),
                                            Color(red: 0.90, green: 0.82, blue: 0.63)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Cute header with emoji
                Text("✨ Congratulations on your roles in society ✨")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(game.players) { p in
                            HStack {
                                Text(p.name)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black)
                                Spacer()
                                if let role = p.role {
                                    Text("\(roleEmojis[role] ?? "❓") \(role.rawValue)")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No Role")
                                        .italic()
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: 300)

                Button("Continue →") {
                    game.votingPhase = .finished
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.top, 12)
            }
            .padding()
        }
    }
}

