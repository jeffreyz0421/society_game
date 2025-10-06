//
//  Society_Communications.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/30/25.
//


import SwiftUI

struct ConversationView: View {
    @ObservedObject var game: GameState
    let me: Int
    let other: Int
    @State private var draft = ""

    var body: some View {
        VStack {
            // Chat scroll
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversation) { m in
                            if m.fromIndex == me {
                                // My messages
                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack(spacing: 6) {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(m.text)
                                                    .padding()
                                                    .background(Color.blue.opacity(0.8))
                                                    .foregroundColor(.white)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                Text("Round \(m.round)")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            Text(playerAvatars[me % playerAvatars.count])
                                                .font(.title2)
                                        }
                                    }
                                }
                            } else {
                                // Other's messages
                                HStack(alignment: .top, spacing: 6) {
                                    Text(playerAvatars[m.fromIndex % playerAvatars.count])
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        if m.isRally {
                                            Text("📣 \(m.text)")
                                                .padding()
                                                .background(Color.yellow.opacity(0.7))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            Text(m.text)
                                                .padding()
                                                .background(Color.green.opacity(0.7))
                                                .foregroundColor(.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        Text("Round \(m.round)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation.map(\.id)) { ids in
                    if let last = ids.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            // Typing bar
            HStack(spacing: 12) {
                TextField("Type your message…", text: $draft)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .font(.system(size: 16, weight: .medium))

                Button(action: {
                    game.sendText(to: other, text: draft)
                    draft = ""
                }) {
                    HStack {
                        Text("Send (-1 gold)")
                        Text("📨")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !game.canAfford(1))
            }
            .padding()
            .background(Color.white.shadow(radius: 2))
        }
        .navigationTitle("Chat with \(game.players[other].name)")
    }

    private var conversation: [ChatMessage] {
        game.conversation(between: me, and: other)
            .sorted { a, b in
                if a.round == b.round {
                    return (game.messages.firstIndex(of: a) ?? 0) < (game.messages.firstIndex(of: b) ?? 0)
                }
                return a.round < b.round
            }
    }
}
