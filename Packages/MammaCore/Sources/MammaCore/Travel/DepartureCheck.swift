import Foundation

/// The signing profile SideStore puts in the app (embedded.mobileprovision). A free Apple ID's lasts
/// seven days, and the app won't open once it has run out.
public struct ProvisioningProfile: Hashable, Sendable {
    /// When SideStore last signed the app.
    public let created: Date?
    public let expires: Date

    public init(created: Date?, expires: Date) {
        self.created = created
        self.expires = expires
    }

    /// Reads the dates from the profile file: a signed message with an XML property list inside.
    /// Nothing else is read; the team name in it is the Apple ID owner's name.
    public init?(data: Data) {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex),
              let dates = try? PropertyListDecoder().decode(Dates.self, from: data.subdata(in: start.lowerBound..<end.upperBound))
        else { return nil }
        self.init(created: dates.created, expires: dates.expires)
    }

    private struct Dates: Decodable {
        let created: Date?
        let expires: Date

        enum CodingKeys: String, CodingKey {
            case created = "CreationDate"
            case expires = "ExpirationDate"
        }
    }
}

/// Whether the app's signature lasts the trip, and when to refresh it if not. Days are the trip's
/// Italian dates; free signing is seven days, so an eight-day trip needs one refresh on the way.
public enum SigningPlan: Hashable, Sendable {
    /// Lasts past the trip's last day.
    case coversTrip(expires: Date)
    /// Runs out during the trip: refresh SideStore on Wi-Fi by the evening of `remindOn`.
    case refreshOnTheWay(expires: Date, remindOn: LocalDate)
    /// Runs out on or before the first day: refresh before leaving.
    case refreshBeforeLeaving(expires: Date)

    /// The refresh reminder comes this many days before the day the signature runs out, so a
    /// failed refresh can be tried again the next evening.
    public static let reminderLead = 2

    /// Nil for a trip without a valid span.
    public init?(expires: Date, trip: Trip) {
        guard let span = trip.span else { return nil }
        let zone = trip.zone ?? TimeZone(identifier: Trip.italyTimeZone) ?? LocalDate.utc
        let lastDay = LocalDate.of(expires, in: zone)
        if lastDay > span.upperBound {
            self = .coversTrip(expires: expires)
        } else if lastDay <= span.lowerBound {
            self = .refreshBeforeLeaving(expires: expires)
        } else {
            self = .refreshOnTheWay(expires: expires, remindOn: max(lastDay.adding(days: -Self.reminderLead), span.lowerBound))
        }
    }

    public var expires: Date {
        switch self {
        case .coversTrip(let expires), .refreshOnTheWay(let expires, _), .refreshBeforeLeaving(let expires): expires
        }
    }
}

/// Where something checked stands.
public enum CheckState: Hashable, Sendable {
    /// Done.
    case ok
    /// Fine as it is, with something to know: the signature needs one refresh on the way.
    case note
    /// The app can't tell, or is still finding out.
    case unknown
    /// Something to do before leaving.
    case todo
}

/// 出发前自检, for the evening before the first city: what the app checks itself and what the
/// learner ticks off.
public struct DepartureCheck: Hashable, Sendable {
    /// The Italian model of the offline speech recognition.
    public enum SpeechModel: Hashable, Sendable {
        case installed, missing, downloading, unsupported, checking, failed
    }

    /// Whether the app may show reminders.
    public enum Permission: Hashable, Sendable {
        case allowed, notAsked, denied, unknown
    }

    /// What only the learner can check.
    public enum Manual: String, CaseIterable, Hashable, Sendable {
        /// SideStore refreshed on the phone, and LocalDevVPN connects.
        case sideStore
        /// Apple Translate has Italian for offline use.
        case translate
        /// Apple Maps has offline maps of the three cities.
        case offlineMaps
    }

    public enum Item: Hashable, Sendable {
        case speechModel(SpeechModel)
        /// Manifest audio files missing from the app; nil until counted.
        case audio(missing: Int?)
        /// Stops without a hotel address, by city id in trip order.
        case hotels(missingAddress: [String])
        /// Show cards not in Photos as they are now, by card id.
        case showCards(unsaved: [String])
        case reminders(Permission)
        /// Nil without a profile to read: a simulator build, or one not installed by SideStore.
        case signing(SigningPlan?)
        case manual(Manual, doneAt: Date?)

        public var state: CheckState {
            switch self {
            case .speechModel(let model):
                switch model {
                case .installed: .ok
                case .unsupported: .note
                case .checking, .downloading: .unknown
                case .missing, .failed: .todo
                }
            case .audio(let missing):
                missing == nil ? .unknown : missing == 0 ? .ok : .todo
            case .hotels(let missing):
                missing.isEmpty ? .ok : .todo
            case .showCards(let unsaved):
                unsaved.isEmpty ? .ok : .todo
            case .reminders(let permission):
                switch permission {
                case .allowed: .ok
                case .unknown: .unknown
                case .notAsked, .denied: .todo
                }
            case .signing(let plan):
                switch plan {
                case .coversTrip?: .ok
                case .refreshOnTheWay?: .note
                case .refreshBeforeLeaving?: .todo
                case nil: .unknown
                }
            case .manual(_, let doneAt):
                doneAt == nil ? .todo : .ok
            }
        }
    }

    public let items: [Item]

    public init(
        trip: Trip,
        speechModel: SpeechModel,
        missingAudio: Int?,
        showCards: [ShowCard],
        savedCards: [String: String],
        reminders: Permission,
        profile: ProvisioningProfile?,
        done: [Manual: Date]
    ) {
        let missingAddress = trip.stops.filter { stop in
            stop.hotel?.address?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        }
        let unsaved = showCards.filter { savedCards[$0.id] != $0.fingerprint }
        var items: [Item] = [
            .speechModel(speechModel),
            .audio(missing: missingAudio),
            .hotels(missingAddress: missingAddress.map(\.city)),
            .showCards(unsaved: unsaved.map(\.id)),
            .reminders(reminders),
            .signing(profile.flatMap { SigningPlan(expires: $0.expires, trip: trip) }),
        ]
        items += Manual.allCases.map { Item.manual($0, doneAt: done[$0]) }
        self.items = items
    }

    /// What is still to do.
    public var todo: [Item] {
        items.filter { $0.state == .todo }
    }

    public var isReady: Bool {
        todo.isEmpty
    }
}

/// A local reminder at an hour of a calendar day wherever the phone is then; the phone changes
/// time zone on landing.
public struct TripReminderTime: Hashable, Sendable {
    public let day: LocalDate
    public let hour: Int

    public init(day: LocalDate, hour: Int) {
        self.day = day
        self.hour = hour
    }

    /// The moment it goes off in `timeZone`.
    public func date(in timeZone: TimeZone) -> Date {
        day.start(in: timeZone, hour: hour)
    }
}

extension Trip {
    /// The local hour of the check's reminder on the evening before the first city, an hour
    /// before that city's pack opens.
    public static let departureCheckHour = 18
    /// The local hour of the reminder to refresh the signature on hotel Wi-Fi.
    public static let signingRefreshHour = 20

    /// The evening before the first arrival, when the check is due.
    public var departureCheckTime: TripReminderTime? {
        span.map { TripReminderTime(day: $0.lowerBound.adding(days: -1), hour: Self.departureCheckHour) }
    }

    /// When to remind about refreshing the signature on the way, if it runs out during the trip.
    public func signingRefreshTime(_ plan: SigningPlan?) -> TripReminderTime? {
        guard case .refreshOnTheWay(_, let day)? = plan else { return nil }
        return TripReminderTime(day: day, hour: Self.signingRefreshHour)
    }
}

extension ShowCard {
    /// Changes whenever anything printed on the card does, so the app can tell whether the image in
    /// Photos still matches. FNV-1a, like the audio's voice pick: the same on every launch.
    public var fingerprint: String {
        var text = id
        for line in lines {
            text += "\u{1E}\(line.style)\u{1F}\(line.text)\u{1F}\(line.zh ?? "")"
        }
        return String(AudioManifest.stableHash(text), radix: 16)
    }
}

extension AudioManifest {
    /// The entries' files that aren't in `directory`, sorted; empty when the build has them all.
    public func missingFiles(in directory: URL) -> [String] {
        Set(entries.values)
            .filter { !FileManager.default.fileExists(atPath: directory.appendingPathComponent($0).path) }
            .sorted()
    }
}
