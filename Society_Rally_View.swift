//
//  Society_Rally_View.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/3/25.
//

import SwiftUI

struct RallyView: View {
    @ObservedObject var game: GameState
    @State private var draftMessage = ""
    var dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("⬅️ Back") { dismiss() }
                Spacer()
                Text("📣 Rally Message")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            TextField("Type your rally message…", text: $draftMessage)
                .textFieldStyle(.roundedBorder)

            Button(action: {
                game.sendRally(text: draftMessage)
                draftMessage = ""
            }) {
                HStack {
                    Text("Send (-5 gold)")
                    Text("📣")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.orange.opacity(0.9))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !game.canAfford(5))

            Spacer()
        }
        .padding()
    }
}
