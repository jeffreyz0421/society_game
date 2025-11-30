//
//  CommScreenRunning.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/21/25.
//

import SwiftUI

struct CommunicationsScreenRunning: View {
    @ObservedObject var game: GameState

    var body: some View {
        NavigationView {
            CampaigningCommunicationsOnly(game: game)
                .navigationTitle("Communications")
        }
    }
}
