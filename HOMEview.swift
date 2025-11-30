//
//  HOMEview.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/22/25.
//

import SwiftUI

struct SocietyHomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // soft pastel background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.88),
                        Color(red: 0.93, green: 0.90, blue: 0.80)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {

                    // 🕶️ Profile button INSIDE the UI (not the macOS title bar)
                    HStack {
                        Spacer()
                        NavigationLink {
                            ProfileView()
                        } label: {
                            VStack(spacing: 4) {
                                Text("🕶️")
                                    .font(.system(size: 28))
                                Text("Profile")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(10)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer(minLength: 40)

                    // Logo + title
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.99, green: 0.96, blue: 0.90),
                                            Color(red: 0.95, green: 0.90, blue: 0.82)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .shadow(radius: 8)

                            Text("🏛️")
                                .font(.system(size: 72))
                        }

                        Text("SOCIETY")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))

                        Text("Political Negotiation Party Game")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    // Play buttons
                    VStack(spacing: 16) {

                        NavigationLink {
                            LocalRoomSetupView()
                        } label: {
                            Text("Play LOCALLY")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.73, green: 0.82, blue: 1.0),
                                            Color(red: 0.53, green: 0.65, blue: 1.0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(radius: 4)
                        }

                        Button {}
                        label: {
                            Text("Play ONLINE (coming soon)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .disabled(true)
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
        }
    }
}
