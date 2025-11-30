//
//  Society_Construction_Screen.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 10/19/25.
//

import SwiftUI

struct SocietyConstructionScreen: View {
    @ObservedObject var manager: InGameManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedProject: BuildingProject.BuildingType? = nil
    @State private var goToBuildPage = false

    var body: some View {
        VStack(spacing: 18) {

            // HEADER
            Text("🏗️ Department of Construction")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .padding(.top, 8)

            // SUMMARY BOX
            GroupBox(label: Text("🏢 Current Construction Summary").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Small Buildings: \(manager.society.smallBuildings)")
                    Text("Big Buildings: \(manager.society.bigBuildings)")
                    Text("Machinery: \(manager.society.machinery)")
                    Text("Raw Materials: \(manager.rawMaterials)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // NEW PROJECT SELECTION
            GroupBox(label: Text("🪵 New Project").font(.headline)) {
                VStack(spacing: 12) {

                    Picker("Select Project Type", selection: $selectedProject) {
                        Text("Small Building")
                            .tag(BuildingProject.BuildingType.smallBuilding as BuildingProject.BuildingType?)

                        Text("Big Building")
                            .tag(BuildingProject.BuildingType.bigBuilding as BuildingProject.BuildingType?)

                        Text("Machinery")
                            .tag(BuildingProject.BuildingType.machinery as BuildingProject.BuildingType?)
                    }
                    .pickerStyle(.menu)

                    Button(action: {
                        if selectedProject != nil {
                            goToBuildPage = true
                        }
                    }) {
                        Label("Start Construction", systemImage: "hammer.fill")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedProject == nil ?
                                        Color.gray.opacity(0.2) :
                                        Color.orange.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedProject == nil)
                }
                .padding()
            }

            Spacer()

            // BACK BUTTON
            Button("⬅️ Back to Game") {
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom)
        }
        .padding()
        .navigationDestination(isPresented: $goToBuildPage) {
            ConstructionBuildPage(
                manager: manager,
                projectType: selectedProject ?? .smallBuilding
            )
        }
    }
}
