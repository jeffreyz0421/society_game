//
//  LOCALROOMsetup.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/22/25.
//

import SwiftUI

struct LocalRoomSetupView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.97, green: 0.95, blue: 0.88),
                    Color(red: 0.93, green: 0.90, blue: 0.80)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Local Room")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("Room creation / code entry TBD.\nFor now, start a local game directly.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                NavigationLink {
                    // existing full game screen
                    ContentView()
                } label: {
                    Text("Start Local Game")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.76, green: 0.93, blue: 0.70),
                                    Color(red: 0.46, green: 0.80, blue: 0.54)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("Play Locally")
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
    }
}
