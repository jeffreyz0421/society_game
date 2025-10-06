//
//  Society_Propose_Promise.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/4/25.
//


import SwiftUI

struct ProposePromiseView: View {
    @ObservedObject var game: GameState
    @Binding var showingPropose: Bool

    @State private var recipientIndex: Int = -1
    @State private var goldAmount: Int = 5
    @State private var selectedRole: Role = .president

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.98, green: 0.95, blue: 0.85),
                            Color(red: 0.95, green: 0.90, blue: 0.75)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 8)
                .padding()

            VStack(spacing: 20) {
                // Title
                HStack {
                    Button("⬅️ Back") { showingPropose = false }
                    Spacer()
                    Text("➕ Promise Proposal")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    // Recipient Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("👤 Recipient")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Picker("Recipient", selection: $recipientIndex) {
                            Text("Choose a player...").tag(-1)
                            ForEach(0..<game.players.count, id: \.self) { idx in
                                if idx != game.currentIndex {
                                    Text("\(playerAvatars[idx % playerAvatars.count]) \(game.players[idx].name)").tag(idx)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    // Gold Offer Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("💰 Gold Offer")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Picker("Gold Offer", selection: $goldAmount) {
                            ForEach([2, 5, 10, 15, 20], id: \.self) { amount in
                                Text("\(amount) gold").tag(amount)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Position Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🎯 Position (their vote for you)")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Picker("Position", selection: $selectedRole) {
                            ForEach(Role.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Send Button
                Button(action: {
                    guard recipientIndex != -1 else { return }
                    game.proposePromise(to: recipientIndex, gold: goldAmount, position: selectedRole)
                    showingPropose = false
                }) {
                    HStack {
                        Text("📜 Send Promise")
                        Text("(-1 gold)")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(recipientIndex == -1)

                Spacer()
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}
