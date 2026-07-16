import Foundation

/// Talks to the SvelteKit backend (apps/web) hosted at fit.berjiljacob.com.
/// Auth is the server's httpOnly cookie session (`luxifit_session`) — URLSession's
/// shared cookie storage persists and re-sends it automatically, so there is no
/// token to manage on the client.
struct APIError: LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}

final class APIClient {
    static let baseURL = URL(string: "https://fit.berjiljacob.com")!

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = .shared
        cfg.httpCookieAcceptPolicy = .always
        cfg.httpShouldSetCookies = true
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.waitsForConnectivity = true
        session = URLSession(configuration: cfg)
    }

    // MARK: - Core request

    private func request(
        _ method: String,
        _ path: String,
        body: Encodable? = nil
    ) async throws -> Data {
        var req = URLRequest(url: Self.baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(status: -1, message: "No response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError(status: http.statusCode, message: Self.errorText(from: data, status: http.statusCode))
        }
        return data
    }

    private func get<T: Decodable>(_ path: String, as: T.Type) async throws -> T {
        let data = try await request("GET", path)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Auth

    @discardableResult
    func login(username: String, password: String) async throws -> AuthUser {
        let data = try await request("POST", "api/auth/login",
                                     body: ["username": username, "password": password])
        return try decoder.decode(AuthUser.self, from: data)
    }

    @discardableResult
    func register(username: String, password: String) async throws -> AuthUser {
        let data = try await request("POST", "api/auth/register",
                                     body: ["username": username, "password": password])
        return try decoder.decode(AuthUser.self, from: data)
    }

    func me() async throws -> AuthUser {
        try await get("api/me", as: AuthUser.self)
    }

    func logout() async throws {
        _ = try? await request("POST", "api/auth/logout")
    }

    // MARK: - Data

    func catalog() async throws -> Catalog {
        try await get("api/catalog", as: Catalog.self)
    }

    func state() async throws -> AppStatePayload {
        try await get("api/state", as: AppStatePayload.self)
    }

    /// Upsert one luxifit.* key. Fire-and-forget from callers.
    func putState(_ key: String, _ value: Encodable) async throws {
        _ = try await request("PUT", "api/state/\(key)", body: value)
    }

    // MARK: - Helpers

    private static func errorText(from data: Data, status: Int) -> String {
        // SvelteKit `error()` responses are { message } (sometimes nested).
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let m = obj["message"] as? String { return m }
            if let e = obj["error"] as? [String: Any], let m = e["message"] as? String { return m }
        }
        return "Request failed (\(status))"
    }
}

/// Type-erasing wrapper so `Encodable` values can be encoded through a generic path.
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeFunc = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
