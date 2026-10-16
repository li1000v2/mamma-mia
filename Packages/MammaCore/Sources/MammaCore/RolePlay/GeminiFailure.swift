import Foundation

/// A failed Gemini call, with the message the learner sees. Authentication and permission errors
/// (401, 403, 404, an invalid key) end the session: retrying can't fix them, and hammering a
/// refused project is how the first one got suspended.
public struct GeminiFailure: Error, Hashable, Sendable, CustomStringConvertible {
    public enum Kind: String, Sendable {
        /// The key, the project or the model is refused: change the settings first.
        case refused
        case rateLimited
        case server
        case badRequest
        case network
        /// The response couldn't be read.
        case malformed
    }

    public let kind: Kind
    /// HTTP status; 0 for network problems and unreadable answers.
    public let status: Int
    /// Google's machine-readable reason, such as API_KEY_INVALID or SERVICE_DISABLED.
    public let reason: String?
    /// Google's own message, for the log. It never contains the key.
    public let detail: String

    public init(kind: Kind, status: Int, reason: String?, detail: String) {
        self.kind = kind
        self.status = status
        self.reason = reason
        self.detail = detail
    }

    /// From an HTTP error response. `redacting` is the key, scrubbed from anything kept.
    public init(status: Int, body: Data, redacting key: String? = nil) {
        if let error = GeminiErrorBody.parse(body) {
            self.init(status: status, error: error, redacting: key)
        } else {
            var text = String(decoding: body.prefix(300), as: UTF8.self)
            if let key, !key.isEmpty { text = text.replacingOccurrences(of: key, with: "<key>") }
            self.init(kind: Self.kind(status: status, reasons: []), status: status, reason: nil, detail: text)
        }
    }

    init(status: Int, error: GeminiErrorBody, redacting key: String? = nil) {
        var detail = [error.status, error.message].compactMap { $0 }.joined(separator: ": ")
        if let key, !key.isEmpty { detail = detail.replacingOccurrences(of: key, with: "<key>") }
        let reasons = error.reasons + (error.message?.localizedCaseInsensitiveContains("suspended") == true ? ["SUSPENDED"] : [])
        self.init(kind: Self.kind(status: status, reasons: reasons), status: status,
                  reason: reasons.first, detail: String(detail.prefix(300)))
    }

    public static func network(_ description: String) -> GeminiFailure {
        GeminiFailure(kind: .network, status: 0, reason: nil, detail: description)
    }

    /// Connected, but nothing came back in time.
    public static func timedOut(_ description: String) -> GeminiFailure {
        GeminiFailure(kind: .network, status: 0, reason: "TIMEOUT", detail: description)
    }

    public static func malformed(_ description: String) -> GeminiFailure {
        GeminiFailure(kind: .malformed, status: 0, reason: nil, detail: description)
    }

    /// Whether the session has to stop until the settings change.
    public var stopsSession: Bool { kind == .refused }

    public var description: String {
        "HTTP \(status) \(reason ?? kind.rawValue): \(detail)"
    }

    /// What went wrong and what to do, in Chinese.
    public var message: String {
        switch reason {
        case "API_KEY_INVALID":
            return "key 无效（\(status)）：到「在线对话设置」重新粘贴完整的 key。"
        case "SERVICE_DISABLED":
            return "这个项目还没启用 Agent Platform API（\(status)）：在 Google Cloud 控制台启用后再试。"
        case "BILLING_DISABLED":
            return "项目没有关联结算账号（\(status)）：在 Google Cloud 控制台关联后再试。"
        case "API_KEY_SERVICE_BLOCKED":
            return "这把 key 的 API 限制里没有 Agent Platform API（\(status)）：在 key 的设置里勾上它。"
        case "API_KEY_IOS_APP_BLOCKED":
            return "这把 key 限定了 iOS 应用，不包括这个 app（\(status)）：把「在线对话设置」里显示的 bundle ID 加进 key 的限制。"
        case "CONSUMER_SUSPENDED", "SUSPENDED":
            return "这个 Google Cloud 项目被停用了（\(status)），在线对话用不了。离线挑战照常能练。"
        case "TIMEOUT":
            return "等了太久没有回应（网络慢或服务忙）：再试一次。"
        default:
            break
        }
        switch kind {
        case .refused:
            switch status {
            case 401:
                return "key 不被接受（401）：到「在线对话设置」检查 key。"
            case 404:
                return "找不到模型或项目（404）：检查项目编号。"
            default:
                return "没有权限（\(status)）：检查 key 的 API 限制、项目的结算账号。离线挑战照常能练。"
            }
        case .rateLimited:
            return "请求太多，被限流了（429）：等一两分钟再说。"
        case .server:
            return "Google 那边暂时出错（\(status)）：稍后再试。"
        case .badRequest:
            return "请求被拒绝（\(status)）：\(detail)"
        case .network:
            return "连不上网：在线对话要联网，离线挑战照常能练。"
        case .malformed:
            return "没看懂服务器的回答，再试一次。"
        }
    }

    static func kind(status: Int, reasons: [String]) -> Kind {
        if reasons.contains(where: { refusingReasons.contains($0) }) { return .refused }
        switch status {
        case 401, 403, 404: return .refused
        case 429: return .rateLimited
        case 500...599: return .server
        case 400...499: return .badRequest
        default: return .malformed
        }
    }

    /// Reasons that come with a 400 but mean the key or project is refused.
    private static let refusingReasons: Set<String> = [
        "API_KEY_INVALID", "SERVICE_DISABLED", "BILLING_DISABLED", "API_KEY_SERVICE_BLOCKED",
        "API_KEY_IOS_APP_BLOCKED", "CONSUMER_SUSPENDED", "SUSPENDED",
    ]
}
