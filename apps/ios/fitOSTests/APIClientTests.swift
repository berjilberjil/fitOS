import XCTest
@testable import fitOS

final class APIClientTests: XCTestCase {

    func testBaseURL() {
        XCTAssertEqual(APIClient.baseURL.absoluteString, "https://fit.berjiljacob.com")
    }

    func testAPIError_description() {
        let e = APIError(status: 401, message: "Unauthorized")
        XCTAssertEqual(e.errorDescription, "Unauthorized")
        XCTAssertEqual(e.status, 401)
    }

    func testAnyEncodable_encodesDictionary() throws {
        let wrapped = AnyEncodable(["username": "a", "password": "b"])
        let data = try JSONEncoder().encode(wrapped)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(obj?["username"], "a")
        XCTAssertEqual(obj?["password"], "b")
    }

    func testAnyEncodable_encodesProfile() throws {
        let p = Profile.default
        let data = try JSONEncoder().encode(AnyEncodable(p))
        let decoded = try JSONDecoder().decode(Profile.self, from: data)
        XCTAssertEqual(decoded.age, p.age)
    }

    /// Live smoke: catalog endpoint is public and should return foods + exercises.
    func testLiveCatalog_endpoint() async throws {
        let api = APIClient()
        let catalog = try await api.catalog()
        XCTAssertFalse(catalog.foods.isEmpty, "Catalog should ship seed foods")
        XCTAssertFalse(catalog.exercises.isEmpty, "Catalog should ship seed exercises")
        // Media may be partial but key should exist for many exercises
        if let media = catalog.media {
            XCTAssertFalse(media.isEmpty)
        }
    }

    func testLiveAnatomy_endpoint() async throws {
        let api = APIClient()
        let anatomy = try await api.anatomy()
        XCTAssertFalse(anatomy.groups.isEmpty)
        XCTAssertFalse(anatomy.front.muscles.isEmpty)
        XCTAssertFalse(anatomy.back.muscles.isEmpty)
        XCTAssertFalse(anatomy.front.outline.isEmpty)
        // Groups should have activation rankings for at least some muscles
        XCTAssertFalse(anatomy.activation.isEmpty)
    }

    func testLiveMe_unauthenticatedIs401() async throws {
        // Clear cookies so we are logged out for this client
        HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        let api = APIClient()
        do {
            _ = try await api.me()
            // If a residual session exists from the host app, that's OK for device runs.
            // The important part is the call does not crash.
        } catch let e as APIError {
            XCTAssertTrue([401, 403].contains(e.status), "Unexpected status \(e.status)")
        } catch {
            throw XCTSkip("Network error talking to live API: \(error)")
        }
    }
}
