import Foundation
import Observation
import Security
import MammaCore

/// Settings and the daily cap for the online role-play. The key is in the Keychain; the project,
/// the reply model and today's turn count are in UserDefaults. None of it is in the progress file
/// or its backups.
@MainActor
@Observable
final class RolePlayService {
    private(set) var hasKey: Bool
    /// The key's last four characters, to tell which one is saved.
    private(set) var keySuffix: String?
    private(set) var project: String
    private(set) var replyModel: ReplyModel
    private(set) var allowance: TurnAllowance
    /// Set when Google refused the key or the project (401/403/404). Nothing more is sent until the
    /// settings change or a connection test passes: retrying a refused project is how the first
    /// one got suspended.
    private(set) var refusal: String?

    @ObservationIgnored private let defaults = UserDefaults.standard

    private enum Keys {
        static let project = "rolePlay.project"
        static let model = "rolePlay.replyModel"
        static let allowance = "rolePlay.allowance"
        static let refusal = "rolePlay.refusal"
    }

    init() {
        let stored = UserDefaults.standard
        let key = KeychainStore.readKey()
        hasKey = key != nil
        keySuffix = key.map { String($0.suffix(4)) }
        project = stored.string(forKey: Keys.project) ?? ""
        replyModel = stored.string(forKey: Keys.model).flatMap(ReplyModel.init(rawValue:)) ?? .argon
        allowance = stored.data(forKey: Keys.allowance)
            .flatMap { try? JSONDecoder().decode(TurnAllowance.self, from: $0) } ?? TurnAllowance()
        refusal = stored.string(forKey: Keys.refusal)
    }

    var isConfigured: Bool {
        hasKey && GeminiEndpoint(project: project) != nil
    }

    /// The client for one session; nil until the key and project are set.
    func client() -> GeminiClient? {
        guard let endpoint = GeminiEndpoint(project: project), let key = KeychainStore.readKey() else { return nil }
        return GeminiClient(key: key, endpoint: endpoint)
    }

    /// The id a key restricted to iOS apps has to allow. SideStore can change it from project.yml's.
    var bundleID: String {
        Bundle.main.bundleIdentifier ?? "?"
    }

    // MARK: Settings

    /// Saves a pasted key; nil when saved, otherwise why not.
    func saveKey(_ pasted: String) -> String? {
        let key = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return "key 是空的。" }
        guard !key.contains(where: \.isWhitespace) else { return "key 中间有空格或换行，检查是否复制完整。" }
        let status = KeychainStore.saveKey(key)
        guard status == errSecSuccess else { return "存进钥匙串失败（\(status)）。" }
        hasKey = true
        keySuffix = String(key.suffix(4))
        clearRefusal()
        AppLog.shared.write("RolePlay: key saved")
        return nil
    }

    func deleteKey() {
        KeychainStore.deleteKey()
        hasKey = false
        keySuffix = nil
        AppLog.shared.write("RolePlay: key deleted")
    }

    func setProject(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != project else { return }
        project = trimmed
        defaults.set(trimmed, forKey: Keys.project)
        clearRefusal()
    }

    func setReplyModel(_ model: ReplyModel) {
        replyModel = model
        defaults.set(model.rawValue, forKey: Keys.model)
    }

    func setDailyLimit(_ limit: Int) {
        allowance.setLimit(limit)
        saveAllowance()
    }

    // MARK: Turns

    func remaining(on day: LocalDate) -> Int {
        allowance.remaining(on: day)
    }

    func used(on day: LocalDate) -> Int {
        allowance.used(on: day)
    }

    @discardableResult
    func spendTurn(on day: LocalDate) -> Bool {
        let spent = allowance.spend(on: day)
        saveAllowance()
        return spent
    }

    // MARK: Refusals

    func noteRefusal(_ failure: GeminiFailure) {
        refusal = failure.message
        defaults.set(failure.message, forKey: Keys.refusal)
        AppLog.shared.write("RolePlay: stopped, \(failure)")
    }

    func clearRefusal() {
        refusal = nil
        defaults.removeObject(forKey: Keys.refusal)
    }

    /// One short Argon request to check the key and project; nil when it answered.
    func testConnection() async -> String? {
        guard let client = client() else { return "先填 key 和项目编号。" }
        let body = GeminiRequest.reply(
            system: "Answer with one word.",
            contents: [GeminiRequest.content(role: "user", text: "Rispondi solo: pronto")]
        )
        let started = Date.now
        do {
            _ = try await client.generate(model: replyModel.rawValue, body: body)
            clearRefusal()
            AppLog.shared.write("RolePlay: connection test passed in \(Self.seconds(since: started))")
            return nil
        } catch let failure as GeminiFailure {
            if failure.stopsSession {
                noteRefusal(failure)
            }
            AppLog.shared.write("RolePlay: connection test failed, \(failure)")
            return failure.message
        } catch {
            return "测试被取消了。"
        }
    }

    static func seconds(since start: Date) -> String {
        String(format: "%.1fs", Date.now.timeIntervalSince(start))
    }

    private func saveAllowance() {
        if let data = try? JSONEncoder().encode(allowance) {
            defaults.set(data, forKey: Keys.allowance)
        }
    }
}
