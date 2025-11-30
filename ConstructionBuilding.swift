//
//  ConstructionBuilding.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/23/25.
//

import SwiftUI

struct ConstructionBuildPage: View {
    @ObservedObject var manager: InGameManager
    let projectType: BuildingProject.BuildingType

    @Environment(\.dismiss) var dismiss

    @State private var rawToSpend: Int = 0
    @State private var goldToSpend: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("🏗️ Build: \(projectType.rawValue)")
                .font(.largeTitle.bold())

            GroupBox(label: Text("Resources Required").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Available Raw Materials: \(manager.rawMaterials)")
                    Text("Your Gold: \(constructionGold())")
                }
            }

            Stepper("Raw Materials: \(rawToSpend)", value: $rawToSpend, in: 0...manager.rawMaterials)
            Stepper("Gold: \(goldToSpend)", value: $goldToSpend, in: 0...Int(constructionGold()))

            Button(action: confirmBuild) {
                Text("✅ Confirm Construction")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button("⬅️ Cancel") {
                dismiss()
            }
            .padding(.bottom)
        }
        .padding()
    }

    private func constructionGold() -> Double {
        manager.game.players.first(where: { $0.role == .construction })?.gold ?? 0
    }

    private func confirmBuild() {
        // Deduct resources
        manager.rawMaterials -= rawToSpend

        if let index = manager.game.players.firstIndex(where: { $0.role == .construction }) {
            manager.game.players[index].gold -= Double(goldToSpend)
        }

        let project = BuildingProject(
            type: projectType,
            turnsRemaining: projectType == .machinery ? 2 : 3,
            initiatedBy: "Construction Dept."
        )

        manager.addProject(project)
        dismiss()
    }
}
