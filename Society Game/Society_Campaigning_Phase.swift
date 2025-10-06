//
//  Society_Campaigning_Phase.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import SwiftUI

// MARK: - emoji avatars for players
let playerAvatars: [String] = [
    "👨‍💼", "🧑‍🎤", "💂‍♀️", "👩‍🏫", "🎅",
    "👩‍🚀", "👩‍💻", "🧑‍🔧", "👻", "🕵️‍♀️"
]

// MARK: - Campaigning View
struct CampaigningView: View {
    @ObservedObject var game: GameState
    @State private var showingInbox = false
    @State private var showingRally = false
    @State private var showingPromises = false

    // cutscene state
    @State private var animating = false
    @State private var animPosition: CGPoint = .zero
    @State private var selectedChatTarget: Int? = nil
    @State private var navigateToChat = false

    var body: some View {
        VStack(spacing: 0) {
            // Stage title
            Text("Stage: Campaigning")
                .font(.system(size: 34, weight: .bold))
                .padding(.top, 8)

            // Subtitle
            Text("COMMUNICATE and prepare for voting!")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .padding(.bottom, 12)

            // Current Player + Gold
            let p = game.currentPlayer
            let idx = game.players.firstIndex(where: { $0.id == p.id }) ?? 0
            HStack(spacing: 12) {
                Text(playerAvatars[idx % playerAvatars.count])
                    .font(.largeTitle)
                Text(p.name)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text("🪙 \(Int(p.gold))")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.yellow)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.orange, lineWidth: 2))
            }
            .padding(.bottom, 10)

            GeometryReader { geo in
                HStack(spacing: 0) {
                    // LEFT SIDE – Communications
                    communicationsPanel(width: geo.size.width * 0.45)

                    Divider()

                    // RIGHT SIDE – oval layout avatars + animation overlay
                    ZStack {
                        ovalAvatarLayout(width: geo.size.width * 0.55,
                                         height: geo.size.height)

                        if animating {
                            Text(playerAvatars[game.currentIndex % playerAvatars.count])
                                .font(.system(size: 40))
                                .position(animPosition)
                        }
                    }
                    .frame(width: geo.size.width * 0.55, height: geo.size.height)
                }
                .onAppear {
                    // initialize animPosition to current player's oval position
                    let (cx, cy) = ovalPosition(for: game.currentIndex,
                                               rightPanelWidth: geo.size.width * 0.55,
                                               rightPanelHeight: geo.size.height)
                    animPosition = CGPoint(x: cx, y: cy)
                }
            }

            Spacer()

            // Bottom bar
            HStack {
                Button("📥 Inbox") { showingInbox = true }
                    .buttonStyle(bottomButtonStyle(color: .blue))
                
                Button("📣 Rally") { showingRally = true }   // <-- CHANGED
                    .buttonStyle(bottomButtonStyle(color: .orange))
                
                Button("🤝 Promises") { showingPromises = true } // <-- NEW
                    .buttonStyle(bottomButtonStyle(color: .green))
                
                Button("➡️ Next Player") { game.nextCampaignPlayer() }
                    .buttonStyle(bottomButtonStyle(color: .purple))
            }

            .padding()
            .background(Color.white.shadow(radius: 4))

            // NavigationLink after cutscene
            NavigationLink(
                destination: Group {
                    if let target = selectedChatTarget {
                        ConversationView(game: game, me: game.currentIndex, other: target)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $navigateToChat
            ) { EmptyView() }
        }
        .background(Color.white)
        .sheet(isPresented: $showingInbox) {
            InboxView(game: game, dismiss: { showingInbox = false })
        }
        .sheet(isPresented: $showingRally) {
            RallyView(game: game, dismiss: { showingRally = false })  // <-- CHANGED
        }
        .sheet(isPresented: $showingPromises) {
            PromisesView(game: game, dismiss: { showingPromises = false }) // <-- NEW
        }

    }

    // MARK: - Left communications list
    private func communicationsPanel(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COMMUNICATIONS")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<game.players.count, id: \.self) { idx in
                        if idx != game.currentIndex {
                            Button {
                                triggerChat(with: idx, rightPanelWidth: width * 1.2, rightPanelHeight: 400)
                            } label: {
                                communicationRow(for: idx)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: width)
        .background(Color.gray.opacity(0.1))
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
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.white)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.3)),
                 alignment: .bottom)
    }

    // MARK: - Oval avatar layout
    private func ovalAvatarLayout(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(0..<game.players.count, id: \.self) { idx in
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
                .onTapGesture {
                    if idx != game.currentIndex {
                        triggerChat(with: idx,
                                    rightPanelWidth: width,
                                    rightPanelHeight: height)
                    }
                }
            }
        }
        .frame(width: width, height: height)
    }

    private func ovalPosition(for idx: Int, rightPanelWidth: CGFloat, rightPanelHeight: CGFloat) -> (CGFloat, CGFloat) {
        let ovalWidth = rightPanelWidth * 0.85
        let ovalHeight = rightPanelHeight * 0.75

        let totalPlayers = game.players.count
        let angleStep = Double.pi * 2 / Double(totalPlayers)
        let angleOffset = -Double.pi / 2

        var angle = angleStep * Double(idx)
        if idx == game.currentIndex {
            angle = Double.pi / 2 // force current player to bottom middle
        }

        let xCenter = rightPanelWidth / 2
        let yCenter = rightPanelHeight / 2

        let x = xCenter + cos(angle + angleOffset) * ovalWidth / 2
        let y = yCenter + sin(angle + angleOffset) * ovalHeight / 2
        return (x, y)
    }

    // MARK: - Trigger chat with animation
    private func triggerChat(with idx: Int, rightPanelWidth: CGFloat, rightPanelHeight: CGFloat) {
        selectedChatTarget = idx

        // start at current player's oval position
        let (cx, cy) = ovalPosition(for: game.currentIndex,
                                   rightPanelWidth: rightPanelWidth,
                                   rightPanelHeight: rightPanelHeight)
        animPosition = CGPoint(x: cx, y: cy)
        animating = true

        // animate to target position
        let (tx, ty) = ovalPosition(for: idx,
                                   rightPanelWidth: rightPanelWidth,
                                   rightPanelHeight: rightPanelHeight)
        withAnimation(.easeInOut(duration: 1)) {
            animPosition = CGPoint(x: tx, y: ty)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            animating = false
            navigateToChat = true
        }
    }

    private func mostRecentMessage(with idx: Int) -> ChatMessage? {
        game.conversation(between: game.currentIndex, and: idx).last
    }

    private func turnsAgo(for round: Int) -> String {
        let diff = game.campaignRound - round
        return diff <= 0 ? "this turn" : "\(diff) turns ago"
    }
}

// MARK: - Custom Button Style
struct bottomButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(color.opacity(configuration.isPressed ? 0.6 : 0.9))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
