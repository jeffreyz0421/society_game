//
//  Society_Main.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import SwiftUI

@main
struct MBGApp: App {
    var body: some Scene {
        WindowGroup {
            SocietyHomeView()   // ✅ Single entry point
        }
    }
}

struct ContentView: View {

    // ✅ Hold both state objects here, created once
    @StateObject private var game: GameState
    @StateObject private var manager: InGameManager

    @State private var showingPlayersSheet = false
    @State private var showingAssignmentReveal = false

    // ✅ Ensure shared instances are built only once
    init() {
        let g = GameState()
        _game = StateObject(wrappedValue: g)
        _manager = StateObject(wrappedValue: InGameManager(game: g))
        print("🟢 ContentView initialized")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // ✅ Campaigning-only button
                if game.stage == .campaigning {
                    Button(action: randomizeRoles) {
                        Label("Randomize Roles", systemImage: "shuffle")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.yellow.opacity(0.3))
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                }

                header
                stageControls

                Divider()

                if game.stage == .ended {
                    LeaderboardsView(game: game)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Society Game Prototype")
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Players") { showingPlayersSheet = true }
                }
#else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Players") { showingPlayersSheet = true }
                }
#endif
            }

            // ✅ Players sheet (shared for all stages)
            .sheet(isPresented: $showingPlayersSheet) {
                PlayersEditor(players: $game.players)
                    .presentationDetents([.medium, .large])
            }

            // ✅ Assignment reveal sheet
            .sheet(isPresented: $showingAssignmentReveal) {
                AssignmentRevealView(game: game, onContinue: {
                    game.stage = .running
                    showingAssignmentReveal = false
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        let p = game.currentPlayer
        return VStack(spacing: 6) {
            if game.stage == .running {
                Text("Turn \(game.turnNumber) / 10")
                    .font(.title2).bold()
                HStack {
                    Text("Current:")
                    Text(p.name).bold()
                    Text("– \(p.role?.rawValue ?? "(Unassigned)")")
                    Spacer()
                    Text("Gold: \(String(format: "%.1f", p.gold))")
                        .monospacedDigit()
                        .padding(6)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Stage Switcher
    @ViewBuilder
    private var stageControls: some View {
        switch game.stage {
        case .campaigning:
            CampaigningView(game: game)

        case .voting:
            VotingView(game: game)

        case .running:
            // ✅ Only ONE place that mounts SocietyPanel
            SocietyPanel(game: game, manager: manager)

        case .ended:
            EmptyView()
        }
    }

    // MARK: - Helper
    private var stageTitle: String {
        switch game.stage {
        case .campaigning: return "Campaigning"
        case .voting: return "Voting"
        case .running: return "Running"
        case .ended: return "Ended"
        }
    }

    // MARK: - Randomize Roles
    private func randomizeRoles() {
        var allRoles = Role.allCases
        guard game.players.count <= allRoles.count else { return }

        allRoles.shuffle()
        for i in 0..<game.players.count {
            game.players[i].role = allRoles[i]
        }

        // ✅ Shows reveal before switching stage
        showingAssignmentReveal = true
    }
}

// MARK: - Players Editor
struct PlayersEditor: View {
    @Binding var players: [Player]
    var body: some View {
        NavigationStack {
            List {
                ForEach(players.indices, id: \.self) { i in
                    HStack {
                        Text("P\(i+1)").foregroundStyle(.secondary)
                        TextField("Name", text: Binding(
                            get: { players[i].name },
                            set: { players[i].name = $0 }
                        ))
                        Spacer()
                        Text("Gold: \(Int(players[i].gold))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Players")
        }
    }
}
