import Foundation

/// Intercepts URLSession traffic for deterministic networking tests.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub {
        var statusCode: Int
        var headers: [String: String]
        var body: Data
        var error: Error?
        var delay: TimeInterval

        init(
            statusCode: Int = 200,
            headers: [String: String] = ["Content-Type": "application/json"],
            body: Data = Data(),
            error: Error? = nil,
            delay: TimeInterval = 0
        ) {
            self.statusCode = statusCode
            self.headers = headers
            self.body = body
            self.error = error
            self.delay = delay
        }
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _requestHandler: ((URLRequest) throws -> Stub)?
    nonisolated(unsafe) private static var _requests: [URLRequest] = []

    static var requestHandler: ((URLRequest) throws -> Stub)? {
        get {
            lock.lock(); defer { lock.unlock() }
            return _requestHandler
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _requestHandler = newValue
        }
    }

    static var requests: [URLRequest] {
        get {
            lock.lock(); defer { lock.unlock() }
            return _requests
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _requests = newValue
        }
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        _requestHandler = nil
        _requests = []
    }

    static func appendRequest(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        _requests.append(request)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.appendRequest(request)

        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let stub = try handler(request)
            if stub.delay > 0 {
                Thread.sleep(forTimeInterval: stub.delay)
            }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: stub.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: stub.headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

enum MockSessionFactory {
    static func make() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }
}

extension URLRequest {
    /// URLProtocol often exposes the body only via `httpBodyStream`.
    func venpays_httpBodyFromStream() -> Data? {
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        let bufferSize = 1024
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data.isEmpty ? nil : data
    }
}
