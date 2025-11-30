import SwiftUI

struct Construction_View: View {
    @ObservedObject var manager: InGameManager

    var body: some View {
        VStack {
            Spacer()

            Button(action: { manager.advanceTurn() }) {
                Label("Next Turn", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.25))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 2)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: 480, maxHeight: .infinity)
    }
}
