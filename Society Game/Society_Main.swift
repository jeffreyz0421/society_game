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
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var game = GameState()
    @State private var showingPlayersSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                header
                stageControls
                Divider()
                if game.stage == .running { turnArea }
                if game.stage == .ended { LeaderboardsView(game: game) }
                Spacer()
            }
            .padding()
            .navigationTitle("Most Basic Game (Prototype)")
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("New Game") { game.resetGame() }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Players") { showingPlayersSheet = true }
                }
#else
                ToolbarItem(placement: .topBarLeading) {
                    Button("New Game") { game.resetGame() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Players") { showingPlayersSheet = true }
                }
#endif
            }
            .sheet(isPresented: $showingPlayersSheet) {
                PlayersEditor(players: $game.players)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: Header
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

    // MARK: Stage Switcher
    private var stageControls: some View {
        Group {
            switch game.stage {
            case .campaigning:
                CampaigningView(game: game)
            case .voting:
                VotingView(game: game)
            case .running:
                SocietyPanel(game: game)
            case .ended:
                EmptyView()
            }
        }
    }

    // MARK: Turn Actions
    private var turnArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions this turn")
                .font(.headline)
            HStack {
                Button("COMMUNICATION (−1g / half if Pres/Trans)") { game.communication() }
                    .disabled(!game.canAfford(game.currentPlayer.role == .president || game.currentPlayer.role == .transportation ? 0.5 : 1.0))
                Button("RALLY (−5g / 2g if Pres)") { game.rally() }
                    .disabled(!game.canAfford(game.currentPlayer.role == .president ? 2.0 : 5.0))
            }
            .buttonStyle(.bordered)

            HStack {
                Button("+1 Gold") { game.earn(1) }
                Button("−1 Gold") { if game.canAfford(1) { game.spend(1) } }
            }
            .buttonStyle(.bordered)

            HStack {
                Spacer()
                Button("End Turn →") { game.endTurn() }
                    .buttonStyle(.borderedProminent)
            }
        }
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
