import Photos
import SwiftUI
import UIKit
import MammaCore

/// Show cards as images in Photos, so they can still be shown when the app's signature has expired
/// and it won't open. Asks only for add-only access: the app never sees the library.
@MainActor
enum PhotoExport {
    enum Failure: Error {
        case denied
        case rendering
    }

    /// One portrait image per card, titled for finding it again in Photos.
    static func images(of cards: [ShowCard], titled title: (ShowCard) -> String) throws -> [UIImage] {
        try cards.map { card in
            let renderer = ImageRenderer(content: ShowCardPoster(card: card, title: title(card)))
            renderer.scale = 3
            guard let image = renderer.uiImage else { throw Failure.rendering }
            return image
        }
    }

    static func save(_ images: [UIImage]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw Failure.denied }
        try await PHPhotoLibrary.shared().performChanges {
            for image in images {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }

    /// What to tell the learner after trying to save `count` cards.
    static func message(saving count: Int, error: Error?) -> String {
        guard let error else {
            return count == 1 ? "已存到相册。" : "\(count) 张出示卡已存到相册。"
        }
        switch error as? Failure {
        case .denied:
            return "没有相册权限：到 设置 → Mamma mia! → 照片 里选“仅添加照片”。"
        case .rendering:
            return "图片没能生成，再试一次。"
        case nil:
            return "没存成：\(error.localizedDescription)"
        }
    }

    /// Renders and saves `cards`: the message to show either way, and whether they were saved.
    static func export(_ cards: [ShowCard], titled title: (ShowCard) -> String) async -> (message: String, saved: Bool) {
        do {
            try await save(images(of: cards, titled: title))
            return (message(saving: cards.count, error: nil), true)
        } catch {
            return (message(saving: cards.count, error: error), false)
        }
    }
}
