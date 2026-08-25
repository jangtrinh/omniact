import XCTest
@testable import OmniAct

final class AccessibilityPermissionReadinessTests: XCTestCase {
    func testStableIdentityKeepsNormalGrantFlow() {
        let signing = AppSigningIdentityStatus(
            kind: .stable,
            identifier: "Apple Development: OmniAct"
        )

        let readiness = AccessibilityPermissionReadiness(
            isAccessibilityGranted: false,
            signingIdentity: signing
        )

        XCTAssertEqual(readiness.state, .notGranted)
        XCTAssertEqual(readiness.statusLabel, "Required")
        XCTAssertEqual(readiness.actionTitle, "Grant Access")
    }

    func testAdHocIdentityIsReportedAsUnstableBeforeGrant() {
        let signing = AppSigningIdentityStatus(kind: .adHoc, identifier: "com.omniact.macos")

        let readiness = AccessibilityPermissionReadiness(
            isAccessibilityGranted: false,
            signingIdentity: signing
        )

        XCTAssertEqual(readiness.state, .unstableBuildIdentity)
        XCTAssertEqual(readiness.statusLabel, "Unstable build")
        XCTAssertEqual(readiness.actionTitle, "Grant for This Build")
        XCTAssertTrue(readiness.detail.contains("OMNIACT_CODESIGN_IDENTITY"))
        XCTAssertTrue(readiness.detail.contains("If Privacy & Security already shows stale"))
    }

    func testAdHocGrantIsExplicitlyTemporary() {
        let signing = AppSigningIdentityStatus(kind: .adHoc, identifier: "com.omniact.macos")

        let readiness = AccessibilityPermissionReadiness(
            isAccessibilityGranted: true,
            signingIdentity: signing
        )

        XCTAssertEqual(readiness.state, .grantedForCurrentBuild)
        XCTAssertEqual(readiness.statusLabel, "Temporary grant")
        XCTAssertTrue(readiness.detail.contains("may stop working after the next rebuild"))
    }

    func testUnsignedOrUnreadableIdentityFailsClosed() {
        let signing = AppSigningIdentityStatus(kind: .unsignedOrUnreadable, identifier: nil)

        let readiness = AccessibilityPermissionReadiness(
            isAccessibilityGranted: false,
            signingIdentity: signing
        )

        XCTAssertEqual(readiness.state, .unstableBuildIdentity)
        XCTAssertFalse(readiness.hasStableSigningIdentity)
        XCTAssertTrue(readiness.detail.contains("could not validate"))
        XCTAssertFalse(readiness.detail.contains("Ad-hoc"))
    }

    func testGrantedUnreadableIdentityIsNotMisdiagnosedAsAdHoc() {
        let signing = AppSigningIdentityStatus(kind: .unsignedOrUnreadable, identifier: nil)
        let readiness = AccessibilityPermissionReadiness(
            isAccessibilityGranted: true,
            signingIdentity: signing
        )

        XCTAssertEqual(readiness.state, .grantedForCurrentBuild)
        XCTAssertEqual(readiness.statusLabel, "Unverified grant")
        XCTAssertTrue(readiness.detail.contains("could not validate"))
        XCTAssertFalse(readiness.detail.contains("ad-hoc"))
    }

    func testTamperedAdHocCodeFailsStrictValidation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OmniActTamperedSignature-\(UUID().uuidString)", isDirectory: true)
        let executable = directory.appendingPathComponent("SignedFixture")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = try XCTUnwrap(Bundle.main.executableURL)
        try Data(contentsOf: source).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        try signAdHoc(executable)

        XCTAssertEqual(AppSigningIdentityStatus.inspect(codeAt: executable).kind, .adHoc)

        let handle = try FileHandle(forWritingTo: executable)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data([0]))
        try handle.close()

        XCTAssertEqual(AppSigningIdentityStatus.inspect(codeAt: executable).kind, .unsignedOrUnreadable)
    }

    private func signAdHoc(_ executable: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--force", "--sign", "-", "--timestamp=none", executable.path]
        process.standardOutput = Pipe()
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? "Unknown codesign error"
            XCTFail(message)
            throw NSError(domain: "AccessibilityPermissionReadinessTests", code: Int(process.terminationStatus))
        }
    }
}
