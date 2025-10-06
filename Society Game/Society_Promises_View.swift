//
//  Society_Promises_View.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/3/25.
//

import SwiftUI
// MARK: - Promises View
struct PromisesView: View {
    @ObservedObject var game: GameState
    @State private var showingCompose = false
    var dismiss: () -> Void
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button("⬅️ Back") { dismiss() }
                Spacer()
                Text("🤝 Promises")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Button(action: { showingCompose = true }) {
                    HStack {
                        Text("➕ Propose One")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(Color.pink.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 3)
                }

            }
            .padding()
            
            ScrollView {
                ForEach(game.promises) { p in
                    promiseCard(p)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                }
            }
        }
        .sheet(isPresented: $showingCompose) {
            ProposePromiseView(game: game, showingPropose: $showingCompose)
        }
    }
    
    @ViewBuilder
    private func promiseCard(_ p: Promise) -> some View {
        let me = game.currentIndex
        let proposer = game.players[p.proposer]
        let recipient = game.players[p.recipient]
        
        VStack(alignment: .leading, spacing: 6) {
            Text("From: \(proposer.name) → To: \(recipient.name)")
                .font(.system(size: 14, weight: .semibold))
            
            Text("💎 Offer: \(p.offer)")
            Text("🗳️ Consideration: \(p.consideration)")
            
            switch p.status {
            case .awaiting:
                if p.proposer == me {
                    Text("⏳ Awaiting response…")
                        .foregroundColor(.blue)
                        .italic()
                } else if p.recipient == me {
                    HStack {
                        Button("✅ Accept") {
                            game.acceptPromise(p.id)
                        }
                        .buttonStyle(bottomButtonStyle(color: .green))
                        Button("❌ Reject") {
                            game.rejectPromise(p.id)
                        }
                        .buttonStyle(bottomButtonStyle(color: .red))
                    }
                }
            case .accepted:
                Text("✅ Accepted").foregroundColor(.green)
            case .rejected:
                Text("❌ Rejected").foregroundColor(.red)
            }
        }
        .padding()
        .background(bgColor(for: p))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
    }
    
    private func bgColor(for p: Promise) -> Color {
        switch p.status {
        case .awaiting:
            return p.proposer == game.currentIndex ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15)
        case .accepted:
            return Color.green.opacity(0.2)
        case .rejected:
            return Color.red.opacity(0.15)
        }
    }
}
