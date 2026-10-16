import SwiftUI
import MammaCore

/// Plays an Italian sentence at normal or slow speed.
struct SpeakButton: View {
    @Environment(AppModel.self) private var model
    let text: String
    var speed: Speed = .normal

    var body: some View {
        Button {
            Task { await model.audio.say(text, speed: speed) }
        } label: {
            Image(systemName: speed == .slow ? "tortoise.fill" : "speaker.wave.2.fill")
                .font(.title3)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(speed == .slow ? "慢速播放" : "播放")
    }
}

extension Grade {
    var label: String {
        switch self {
        case .again: "重来"
        case .hard: "困难"
        case .good: "记得"
        case .easy: "轻松"
        }
    }

    var tint: Color {
        switch self {
        case .again: .red
        case .hard: .orange
        case .good: .green
        case .easy: .blue
        }
    }
}

/// A course-map row: id, title, focus and whether it's done.
struct UnitRow: View {
    @Environment(AppModel.self) private var model
    let unit: CourseUnit

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(unit.id)
                .font(.caption.monospaced())
                .foregroundStyle(unit.kind == .challenge ? Color.orange : Color.secondary)
                .frame(width: 32, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(unit.title)
                Text(unit.focus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusIcon
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if unit.kind == .lesson, model.progress.isCompleted(unit.id) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        } else if unit.kind == .challenge, model.progress.hasPassed(unit.id) {
            Image(systemName: "star.fill").foregroundStyle(.orange)
        } else if unit.kind == .challenge, !model.progress.runs(of: unit.id).isEmpty {
            Image(systemName: "circle.dashed").foregroundStyle(.secondary)
        }
    }
}

/// A row that opens the unit's overview, from which the lesson or challenge starts.
struct UnitLink: View {
    let unit: CourseUnit

    var body: some View {
        NavigationLink {
            UnitDetailView(unit: unit)
        } label: {
            UnitRow(unit: unit)
        }
    }
}
