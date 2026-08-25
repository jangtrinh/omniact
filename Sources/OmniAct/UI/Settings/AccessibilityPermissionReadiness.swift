import Foundation

enum AccessibilityPermissionReadinessState: Equatable, Sendable {
    case granted
    case grantedForCurrentBuild
    case notGranted
    case unstableBuildIdentity
}

struct AccessibilityPermissionReadiness: Equatable, Sendable {
    let state: AccessibilityPermissionReadinessState
    let signingIdentity: AppSigningIdentityStatus

    init(isAccessibilityGranted: Bool, signingIdentity: AppSigningIdentityStatus) {
        self.signingIdentity = signingIdentity
        switch (isAccessibilityGranted, signingIdentity.isStableForTCC) {
        case (true, true):
            state = .granted
        case (true, false):
            state = .grantedForCurrentBuild
        case (false, true):
            state = .notGranted
        case (false, false):
            state = .unstableBuildIdentity
        }
    }

    var hasStableSigningIdentity: Bool {
        signingIdentity.isStableForTCC
    }

    var statusLabel: String {
        switch state {
        case .granted:
            "Granted"
        case .grantedForCurrentBuild:
            signingIdentity.kind == .adHoc ? "Temporary grant" : "Unverified grant"
        case .notGranted:
            "Required"
        case .unstableBuildIdentity:
            "Unstable build"
        }
    }

    var actionTitle: String {
        state == .unstableBuildIdentity ? "Grant for This Build" : "Grant Access"
    }

    var detail: String {
        switch state {
        case .granted:
            "Accessibility is enabled for this stable app identity. Support still depends on the active app."
        case .grantedForCurrentBuild:
            grantedUnstableIdentityDetail
        case .notGranted:
            "Grant Accessibility access once for this stable app identity."
        case .unstableBuildIdentity:
            identityRecoveryDetail
        }
    }

    private var identityRecoveryDetail: String {
        if signingIdentity.kind == .adHoc {
            return "Ad-hoc signing changes OmniAct’s identity after rebuilds. Rebuild with "
                + "OMNIACT_CODESIGN_IDENTITY set. If Privacy & Security already shows stale "
                + "OmniAct entries, remove them, then grant access once."
        }
        return "OmniAct could not validate this build’s code-signing identity. Rebuild with "
            + "OMNIACT_CODESIGN_IDENTITY set before granting access."
    }

    private var grantedUnstableIdentityDetail: String {
        if signingIdentity.kind == .adHoc {
            return "Accessibility is enabled, but this ad-hoc grant may stop working after the next rebuild."
        }
        return "Accessibility is enabled, but OmniAct could not validate this build’s signing identity. "
            + "Rebuild before relying on the permission across updates."
    }
}
