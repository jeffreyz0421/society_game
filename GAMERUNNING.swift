import SwiftUI

struct SocietyGameRunningPhaseView<Content: View>: View {
    @ObservedObject var manager: InGameManager
    let content: () -> Content

    // Local sheets
    @State private var showingChat = false
    @State private var showingInbox = false
    @State private var showingRally = false
    @State private var showingPromises = false
    @State private var showingConstruction = false
    @State private var showingPresidentialActions = false

    

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 12) {

                // MARK: - Chat Button
                HStack {
                    Spacer()
                    Button("💬 Chat") { showingChat = true }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
                
                NavigationLink(
                                    destination: RunningChatView(game: manager.game),
                                    isActive: $showingChat
                                ) {
                                    EmptyView()
                                }
                                .hidden()



                // MARK: - Role Header (under Chat)
                if let role = manager.game.currentPlayer.role {
                    VStack(spacing: 2) {
                        Text("\(role.rawValue)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("\(manager.game.currentPlayer.name)’s Turn")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }

                // MARK: - Society Overview
                GroupBox(label: Text("📊 Society Overview").font(.headline)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("👥 Population: \(manager.society.population.count)")
                        Text("🍞 Food Storage: \(manager.society.foodStorage.count)")
                        Text("🪨 Raw Materials: \(manager.rawMaterials)")
                        Text("⚙️ Machinery: \(manager.society.machinery)")
                    }
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)

                // MARK: - Player Circle (centered, current player highlighted)
                ZStack {
                    GeometryReader { geo in
                        let circleRadius = min(geo.size.width, geo.size.height) * 0.52
                        let circleSize = circleRadius * 2.0
                        let centerX = geo.size.width / 2
                        let centerY = geo.size.height / 2.15

                        // Base Circle
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: circleSize, height: circleSize)
                            .position(x: centerX, y: centerY)
                            .shadow(radius: 6)

                        // Loop through each player role
                        ForEach(0..<10, id: \.self) { index in
                            let angle = Double(index) / 10.0 * 2 * Double.pi - Double.pi / 2

                            // 🔥 Highlight based on turn position, not role name
                            let isCurrent = index == manager.game.roleTurnPos

                            VStack(spacing: 3) {
                                ZStack {
                                    // Highlight ring (behind emoji)
                                    if isCurrent {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.yellow.opacity(0.7), .orange.opacity(0.4)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 64, height: 64)
                                            .shadow(color: .orange.opacity(0.5), radius: 10)
                                            .transition(.scale)
                                            .animation(.easeInOut(duration: 0.3), value: isCurrent)
                                    }

                                    // Emoji
                                    Text(inGamePlayerAvatars[index])
                                        .font(.system(size: isCurrent ? 52 : 36))
                                        .scaleEffect(isCurrent ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isCurrent)
                                }

                                // Role label
                                Text(roleLabels[index])
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(isCurrent ? .black : .secondary)
                            }
                            .position(
                                x: centerX + CGFloat(cos(angle)) * circleRadius,
                                y: centerY + CGFloat(sin(angle)) * circleRadius
                            )
                        }
                    }
                }
                .frame(height: 360)



                // MARK: - Injected Role Content
                content()
                    .padding(.horizontal, 24)

                // MARK: - Bottom Buttons
                HStack(spacing: 6) {
                    bottomButton("📥 Inbox", color: .blue) { showingInbox = true }
                    bottomButton("📣 Rally", color: .orange) { showingRally = true }
                    bottomButton("🤝 Promises", color: .green) { showingPromises = true }

                    if manager.game.currentPlayer.role == .president {
                        bottomButton("🎩 Prez Actions", color: .purple) {
                            showingPresidentialActions = true
                        }
                    } else {
                        bottomButton("🏗️ Build", color: .purple) {
                            showingConstruction = true
                        }
                    }
                }
                .padding(.bottom, 14)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.88),
                        Color(red: 0.93, green: 0.90, blue: 0.80)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $showingInbox) {
                    InboxView(
                        game: manager.game,
                        dismiss: { showingInbox = false }
                    )
                }
        .sheet(isPresented: $showingRally) {
                    RallyView(
                        game: manager.game,
                        dismiss: { showingRally = false }
                    )
                }
        .sheet(isPresented: $showingPromises) {
                    PromisesView(
                        game: manager.game,
                        dismiss: { showingPromises = false }
                    )
                }
        .sheet(isPresented: $showingPresidentialActions) {
                PresidentialActionsView(game: manager.game)
            }
        .sheet(isPresented: $showingConstruction) {
            SocietyConstructionScreen(manager: manager)
        }

    }

    // MARK: - Button Component
    private func bottomButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(color)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 2)
        }
    }
}

// MARK: - Constants
let inGamePlayerAvatars = ["🎩","⚖️","🏦","🧑‍🏭","🎓","🚧","🚗","🏥","🌾","⛏️"]
let roleLabels = ["President","SCCJ","Treasury","Labor","Education","Construction","Transport","Health","Agriculture","Resource"]
