import SwiftUI

struct DialogueView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "情境挑战还没上线",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("10 个离线剧本对话会在 P0 里加进来，先用点选作答。")
            )
            .navigationTitle("对话")
        }
    }
}

struct TravelView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "随身模式还没上线",
                systemImage: "map",
                description: Text("出示卡、应急句和巡礼点会在后面的版本加进来。")
            )
            .navigationTitle("随身")
        }
    }
}
