//
//  CampaignCommOnly.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/21/25.
//

import SwiftUI

struct CampaigningCommunicationsOnly: View {
    @ObservedObject var game: GameState

    var body: some View {
        VStack {
            // reuse the same communications list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<game.players.count, id: \.self) { idx in
                        if idx != game.currentIndex {
                            NavigationLink(
                                destination: ConversationView(
                                    game: game,
                                    me: game.currentIndex,
                                    other: idx
                                )
                            ) {
                                communicationRow(for: idx)
                            }
                        }
                    }
                }
            }
        }
    }

    private func communicationRow(for idx: Int) -> some View {
        HStack(spacing: 12) {
            Text(playerAvatars[idx % playerAvatars.count])
                .font(.largeTitle)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(game.players[idx].name)
                    .font(.system(size: 16, weight: .semibold))
                Text("Tap to chat")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.white)
    }
}
