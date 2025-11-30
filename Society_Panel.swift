//
//  SocietyPanel.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/19/25.
//

import SwiftUI

/// Main view used when the game is in the "Running" phase.
/// Dynamically loads the correct in-game view based on the player’s role.
struct SocietyPanel: View {
    @ObservedObject var game: GameState
    @ObservedObject var manager: InGameManager
    init(game: GameState, manager: InGameManager) {
        self.game = game
        self.manager = manager
        print("🟣 SocietyPanel initialized")
    }

    var body: some View {
        let currentRole = game.currentPlayer.role ?? .labor

        // ✅ Wrap the switch in a Group to ensure consistent return type
        SocietyGameRunningPhaseView(manager: manager) {
            Group {
                switch currentRole {
                case .president:
                    Pres_View(manager: manager)

                case .sccj:
                    SCCJ_View(manager: manager)

                case .treasury:
                    Treasury_View(manager: manager)

                case .labor:
                    Labor_View(manager: manager)

                case .education:
                    Education_View(manager: manager)

                case .construction:
                    Construction_View(manager: manager)

                case .transportation:
                    Transportation_View(manager: manager)

                case .publicHealth:
                    PublicHealth_View(manager: manager)

                case .agriculture:
                    Agriculture_View(manager: manager)

                case .resource:
                    ResourceAllo_View(manager: manager)
                }
            }
        }
    }
}
