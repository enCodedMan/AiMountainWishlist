import SwiftUI

/// App entry point. Intentionally minimal at this stage (M0 repo
/// scaffold) — auth, onboarding, and the real navigation shell land in
/// M1 per docs/architecture.md.
@main
struct StonesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
