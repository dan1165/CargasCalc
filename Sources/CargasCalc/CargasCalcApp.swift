import SwiftUI

@main
struct CargasCalcApp: App {
    @State private var history = HistoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(history)
                .preferredColorScheme(.dark)
                .tint(.white)
        }
    }
}
