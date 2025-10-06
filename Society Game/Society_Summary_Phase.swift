//
//  Society_Summary_Phase.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import SwiftUI

// MARK: - End Game Summary Phase (Leaderboards & Results)

struct LeaderboardsView: View {
    @ObservedObject var game: GameState

    private var totalPoints: Int { game.society.totalSocietyPoints() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎉 Game Over – 10 Turns Completed")
                .font(.title2).bold()

            // --- Society Results ---
            Text("Society Leaderboard (this game)")
                .font(.headline)

            Text("Total Society Points: \(totalPoints)")
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // --- Personal Results ---
            Text("Personal Leaderboard")
                .font(.headline)
                .padding(.top, 8)

            let ranked = game.players.sorted { $0.personalScore > $1.personalScore }

            ForEach(Array(ranked.enumerated()), id: \.offset) { idx, p in
                HStack {
                    Text("\(idx+1).")
                        .frame(width: 24, alignment: .trailing)

                    VStack(alignment: .leading) {
                        Text(p.name).bold()
                        Text(p.role?.rawValue ?? "Role: N/A")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(String(format: "%.0f pts", p.personalScore))
                            .bold()
                        Text(String(format: "Gold bonus: %.0f", 10 * p.gold))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // --- Restart Button ---
            HStack {
                Spacer()
                Button("Play Again") { game.resetGame() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
