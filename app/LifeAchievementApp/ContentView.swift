import SwiftUI

/// Placeholder root view proving the project scaffold builds and links
/// against `LifeAchievementCore`. Replaced by real navigation (auth /
/// onboarding / home) starting in M1 — not a feature, just scaffolding.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Stones")
                .font(.largeTitle.bold())
            Text("The phone is the scoreboard.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
