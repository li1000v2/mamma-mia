import Foundation
import MammaCore

/// Calls Agent Platform with the learner's own key, for the online role-play only. Streams over
/// :streamGenerateContent?alt=sse; every refusal comes back as a `GeminiFailure`, with the key
/// scrubbed from anything that could reach the screen or the log.
struct GeminiClient {
    let key: String
    let endpoint: GeminiEndpoint

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        // Seconds without a byte before giving up; Argon has been seen taking 20 s to start.
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

    /// The events of one streamed call, as they arrive. Cancelling the consuming task cancels the request.
    func stream(model: String, body: JSONValue) -> AsyncThrowingStream<GeminiStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try makeRequest(url: endpoint.streamURL(model: model), body: body)
                    let (bytes, response) = try await Self.session.bytes(for: request)
                    if let status = (response as? HTTPURLResponse)?.statusCode, status != 200 {
                        var data = Data()
                        for try await byte in bytes {
                            data.append(byte)
                            if data.count > 64_000 { break }
                        }
                        throw GeminiFailure(status: status, body: data, redacting: key)
                    }
                    var parser = GeminiStreamParser()
                    for try await line in bytes.lines {
                        for event in try parser.feed(line: line) {
                            continuation.yield(event)
                        }
                    }
                    for event in try parser.finish() {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Self.failure(from: error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// One whole answer, for the feedback card and the connection test.
    func generate(model: String, body: JSONValue) async throws -> GeminiResponse {
        do {
            let request = try makeRequest(url: endpoint.url(model: model), body: body)
            let (data, response) = try await Self.session.data(for: request)
            if let status = (response as? HTTPURLResponse)?.statusCode, status != 200 {
                throw GeminiFailure(status: status, body: data, redacting: key)
            }
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            _ = try decoded.events() // an error object inside a 200 answer
            return decoded
        } catch {
            throw Self.failure(from: error)
        }
    }

    private func makeRequest(url: URL, body: JSONValue) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        // Lets a key restricted to iOS apps accept the request; SideStore may have changed the id.
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        request.httpBody = try body.encoded()
        return request
    }

    /// Cancellation stays cancellation; network trouble and unreadable answers become failures.
    private static func failure(from error: Error) -> Error {
        switch error {
        case is GeminiFailure, is CancellationError:
            return error
        case let urlError as URLError where urlError.code == .cancelled:
            return CancellationError()
        case let urlError as URLError where urlError.code == .timedOut:
            return GeminiFailure.timedOut(urlError.localizedDescription)
        case let urlError as URLError:
            return GeminiFailure.network(urlError.localizedDescription)
        case is DecodingError:
            return GeminiFailure.malformed(String(describing: error))
        default:
            return GeminiFailure.network(error.localizedDescription)
        }
    }
}
