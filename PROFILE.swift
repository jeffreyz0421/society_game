

//
//  ProfileView.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/22/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("🕶️ Profile")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .padding(.top, 40)

            Text("Profile screen coming soon...")
                .foregroundColor(.secondary)
                .padding(.top, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .navigationTitle("Profile")
    }
}
