import SwiftUI

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
