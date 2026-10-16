import SwiftUI

@main
struct MammaMiaApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            Tab("今日", systemImage: "sun.max") { TodayView() }
            Tab("课程", systemImage: "book") { LessonsView() }
            Tab("对话", systemImage: "bubble.left.and.bubble.right") { DialogueView() }
            Tab("随身", systemImage: "map") { TravelView() }
        }
    }
}
