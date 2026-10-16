import Foundation

/// One of the 12 all-purpose sentence frames the course is built on.
public struct Frame: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let pattern: String
    public let use: String
    public let example: String
}

/// A situation the course teaches for (bar, boat, train…). `neededAt` says when on the trip it is
/// first needed — "first", "last", "city:<id>" or "event:<id>" — and is resolved against the trip.
public struct SceneTag: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let zh: String
    public let neededAt: String
}

public enum UnitKind: String, Codable, Sendable {
    case lesson
    case challenge
}

/// A lesson (L01–L30) or situational challenge (C01–C10) in the course map.
public struct CourseUnit: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let kind: UnitKind
    public let week: Int
    public let title: String
    /// The frame or grammar point the unit is about, as shown in the course map.
    public let focus: String
    public let frames: [String]
    public let scene: String
    /// Key expressions for a lesson, or the task list for a challenge.
    public let summary: String
}

/// Content/course.json: the frames, scenes and the ordered course map.
public struct Course: Codable, Sendable {
    public let version: Int
    public let frames: [Frame]
    public let scenes: [SceneTag]
    public let units: [CourseUnit]
}

/// Where a phrase is in the drafting → cross-check → native check → audio review pipeline.
public enum ReviewStatus: String, Codable, Sendable, CaseIterable, Comparable {
    case draft
    case checked
    case native
    case audioOK = "audio_ok"

    public static func < (lhs: ReviewStatus, rhs: ReviewStatus) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

/// One Italian expression with its Chinese meaning. Self-referential sentences use the masculine
/// form and strangers are addressed with Lei.
public struct Phrase: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let it: String
    public let zh: String
    public let frame: String?
    public let scene: String
    public let status: ReviewStatus
    public let note: String?
}

/// Content/lessons/<unit>.json.
public struct LessonContent: Codable, Sendable {
    public let unit: String
    public let phrases: [Phrase]
}
