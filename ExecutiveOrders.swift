//
//  ExecutiveOrders.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/22/25.
//

import SwiftUI

struct ExecutiveOrdersView: View {
    @ObservedObject var game: GameState

    var body: some View {
        VStack(spacing: 16) {
            Text("Executive Orders")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("Here you’ll later pick which department to enforce which project on, and schedule when it takes effect.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}
