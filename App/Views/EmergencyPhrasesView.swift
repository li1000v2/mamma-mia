import SwiftUI
import MammaCore

/// 应急句: the emergency and pharmacy sentences on one page, each playable, with 112 on top.
struct EmergencyPhrasesView: View {
    @Environment(AppModel.self) private var model

    static let scenes = ["emergency", "pharmacy"]
    static let call112 = URL(string: "tel:\(ShowCard.emergencyNumber)")

    var body: some View {
        List {
            Section {
                if let url = Self.call112 {
                    Link(destination: url) {
                        Label("拨打 \(ShowCard.emergencyNumber)", systemImage: "phone.fill")
                            .font(.headline)
                    }
                    .foregroundStyle(.red)
                }
                if let card = model.showCards.first(where: { $0.kind == .emergency }) {
                    NavigationLink {
                        ShowCardDetailView(card: card)
                    } label: {
                        Label("112 出示卡", systemImage: "person.text.rectangle")
                    }
                }
            } footer: {
                Text("112 是欧盟统一的紧急电话，在意大利免费拨打。")
            }
            if let content = model.content {
                ForEach(Self.scenes, id: \.self) { id in
                    if let scene = content.scene(id) {
                        Section(scene.zh) {
                            ForEach(content.phrases(inScene: id)) { phrase in
                                TravelPhraseRow(phrase: phrase)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("应急句")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            model.audio.stop()
        }
    }
}
