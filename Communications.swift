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

struct RunningChatView: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {

                // Top bar
                HStack {
                    Button("⬅︎ Back to Game") {
                        dismiss()   // works when this view is pushed in a NavigationStack
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text("Chat Center")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Spacer()

                    // spacer to balance back button
                    Color.clear.frame(width: 80, height: 1)
                }
                .padding()
                .background(Color.white.opacity(0.95))

                Divider()

                // Main content
                HStack(spacing: 0) {
                    communicationsPanel(width: geo.size.width * 0.35)
                    Divider()
                    ovalAvatarLayout(
                        width: geo.size.width * 0.65,
                        height: geo.size.height - 60
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.06))
        }
        // full-screen by default when pushed
    }

    // MARK: - Communications list

    private func communicationsPanel(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COMMUNICATIONS")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.horizontal)
                .padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<game.players.count, id: \.self) { idx in
                        if idx != game.currentIndex {
                            NavigationLink {
                                // ⬅️ full-screen chat view, no floating sheet
                                ConversationView(
                                    game: game,
                                    me: game.currentIndex,
                                    other: idx
                                )
                            } label: {
                                communicationRow(for: idx)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: width)
        .background(Color.gray.opacity(0.08))
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
                    .foregroundColor(.black)

                if let last = mostRecentMessage(with: idx) {
                    Text(last.text)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                } else {
                    Text("No messages yet")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if let last = mostRecentMessage(with: idx) {
                Text(turnsAgo(for: last.round))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .bottom
        )
    }

    // MARK: - Oval avatars (same as before)

    private func ovalAvatarLayout(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(Array(game.players.indices), id: \.self) { idx in
                let (x, y) = ovalPosition(for: idx,
                                          rightPanelWidth: width,
                                          rightPanelHeight: height)

                VStack {
                    Text(playerAvatars[idx % playerAvatars.count])
                        .font(.system(size: 40))
                    Text(game.players[idx].name)
                        .font(.caption)
                }
                .position(x: x, y: y)
            }
        }
    }

    private func ovalPosition(for idx: Int,
                              rightPanelWidth: CGFloat,
                              rightPanelHeight: CGFloat) -> (CGFloat, CGFloat) {
        let ovalWidth = rightPanelWidth * 0.85
        let ovalHeight = rightPanelHeight * 0.75

        let totalPlayers = game.players.count
        let angleStep = Double.pi * 2 / Double(totalPlayers)
        let angleOffset = -Double.pi / 2

        var angle = angleStep * Double(idx)
        if idx == game.currentIndex {
            angle = Double.pi / 2 // current player at bottom
        }

        let xCenter = rightPanelWidth / 2
        let yCenter = rightPanelHeight / 2

        let x = xCenter + cos(angle + angleOffset) * ovalWidth / 2
        let y = yCenter + sin(angle + angleOffset) * ovalHeight / 2
        return (x, y)
    }

    // MARK: - Helpers

    private func mostRecentMessage(with idx: Int) -> ChatMessage? {
        game.conversation(between: game.currentIndex, and: idx).last
    }

    private func turnsAgo(for round: Int) -> String {
        let diff = game.campaignRound - round
        return diff <= 0 ? "this turn" : "\(diff) turns ago"
    }
}
