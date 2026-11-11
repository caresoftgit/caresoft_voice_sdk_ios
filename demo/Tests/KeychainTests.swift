import CaresoftVoice
import XCTest

@testable import CaresoftVoiceDemo

final class KeychainTests: XCTestCase {
  func testSimulatorHostCanPersistAndClearSDKSession() async throws {
    // Use a unique service so this check never reads or removes a real login.
    let store = KeychainSessionStore(
      domain: "keychain-smoke", appId: UUID().uuidString,
      applicationId: "com.example.CaresoftVoiceDemo")
    do {
      let empty = try await store.read()
      XCTAssertNil(empty)
      let first = Data("dummy-session".utf8)
      try await store.write(first)
      let restored = try await store.read()
      XCTAssertEqual(restored, first)
      let updated = Data("dummy-session-updated".utf8)
      try await store.write(updated)
      let restoredUpdate = try await store.read()
      XCTAssertEqual(restoredUpdate, updated)
      try await store.clear()
      let cleared = try await store.read()
      XCTAssertNil(cleared)
    } catch {
      try? await store.clear()
      throw error
    }
  }
}

final class CallingLineTests: XCTestCase {
  func testPermissionListUsesCalloutIDAndLabels() throws {
    let data = Data(
      #"{"res":{"lstCalloutPermission":[{"callout_id":42,"descriptions":"Hotline A","is_default":1},{"callout_id":"73","descriptions":"Hotline B"},{"callout_id":42,"descriptions":"Duplicate"},{"descriptions":"Missing"}]}}"#
        .utf8)
    let lines = try DemoCallingLine.parse(data)
    XCTAssertEqual(lines.map(\.id), ["42", "73"])
    XCTAssertEqual(lines.map(\.label), ["Hotline A", "Hotline B"])
    XCTAssertTrue(lines[0].isDefault)
    XCTAssertFalse(lines[1].isDefault)
    XCTAssertThrowsError(try DemoCallingLine.parse(Data(#"{"status":"notLogin"}"#.utf8)))
    XCTAssertEqual(
      try DemoCallingLine.parse(Data(#"{"res":{"lstCalloutPermission":[]}}"#.utf8)), [])
  }
}
