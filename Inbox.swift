//
//  Society_Chat_Inbox.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/1/25.
//

import SwiftUI

struct InboxView: View {
    @ObservedObject var game: GameState
    var dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("⬅️ Back") { dismiss() }
                Spacer()
                Text("Inbox").font(.title2).bold()
                Spacer()
            }
            .padding(.bottom, 8)

            ScrollView {
                ForEach(game.inbox(for: game.currentIndex)) { m in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From \(game.players[m.fromIndex].name)")
                            .font(.headline)
                        Text(m.text)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
    }
}
