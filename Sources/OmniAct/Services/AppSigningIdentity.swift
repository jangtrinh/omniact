import Foundation
import Security

enum AppSigningIdentityKind: Equatable, Sendable {
    case stable
    case adHoc
    case unsignedOrUnreadable
}

struct AppSigningIdentityStatus: Equatable, Sendable {
    private static let adHocSignatureFlag: UInt32 = 0x0002

    let kind: AppSigningIdentityKind
    let identifier: String?

    var isStableForTCC: Bool {
        kind == .stable
    }

    static func current() -> AppSigningIdentityStatus {
        let codeURL = Bundle.main.bundleURL.pathExtension == "app"
            ? Bundle.main.bundleURL
            : Bundle.main.executableURL
        guard let codeURL else {
            return AppSigningIdentityStatus(kind: .unsignedOrUnreadable, identifier: nil)
        }

        return inspect(codeAt: codeURL)
    }

    static func inspect(codeAt codeURL: URL) -> AppSigningIdentityStatus {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(codeURL as CFURL, [], &code) == errSecSuccess,
              let code else {
            return AppSigningIdentityStatus(kind: .unsignedOrUnreadable, identifier: nil)
        }

        let validityFlags = SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures)
        guard SecStaticCodeCheckValidity(code, validityFlags, nil) == errSecSuccess else {
            return AppSigningIdentityStatus(kind: .unsignedOrUnreadable, identifier: nil)
        }

        var signingInformation: CFDictionary?
        let status = SecCodeCopySigningInformation(
            code,
            SecCSFlags(rawValue: kSecCSSigningInformation),
            &signingInformation
        )
        guard status == errSecSuccess,
              let information = signingInformation as? [CFString: Any] else {
            return AppSigningIdentityStatus(kind: .unsignedOrUnreadable, identifier: nil)
        }

        let identifier = information[kSecCodeInfoIdentifier] as? String
        let flags = (information[kSecCodeInfoFlags] as? NSNumber)?.uint32Value ?? 0
        let isAdHoc = flags & adHocSignatureFlag != 0
        if isAdHoc {
            return AppSigningIdentityStatus(kind: .adHoc, identifier: identifier)
        }

        let certificates = information[kSecCodeInfoCertificates] as? [SecCertificate]
        guard certificates?.isEmpty == false else {
            return AppSigningIdentityStatus(kind: .unsignedOrUnreadable, identifier: identifier)
        }
        return AppSigningIdentityStatus(kind: .stable, identifier: identifier)
    }
}
