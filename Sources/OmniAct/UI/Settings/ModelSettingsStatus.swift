import Foundation

enum ModelSettingsStatus: Equatable {
    case idle
    case detectingModels
    case modelsDetected(count: Int)
    case testing(providerName: String)
    case connected
    case failed(message: String)
    case saved

    var presentation: ModelSettingsStatusPresentation {
        switch self {
        case .idle:
            ModelSettingsStatusPresentation(
                message: "Test this provider before saving.",
                symbol: "bolt.horizontal.circle",
                tone: .secondary,
                showsProgress: false
            )
        case .detectingModels:
            ModelSettingsStatusPresentation(
                message: "Detecting available models…",
                symbol: nil,
                tone: .secondary,
                showsProgress: true
            )
        case let .modelsDetected(count):
            ModelSettingsStatusPresentation(
                message: "Found \(count) available models",
                symbol: "checkmark.circle.fill",
                tone: .success,
                showsProgress: false
            )
        case let .testing(providerName):
            ModelSettingsStatusPresentation(
                message: "Testing \(providerName)…",
                symbol: nil,
                tone: .secondary,
                showsProgress: true
            )
        case .connected:
            ModelSettingsStatusPresentation(
                message: "Connection verified",
                symbol: "checkmark.circle.fill",
                tone: .success,
                showsProgress: false
            )
        case let .failed(message):
            ModelSettingsStatusPresentation(
                message: message,
                symbol: "exclamationmark.triangle.fill",
                tone: .warning,
                showsProgress: false
            )
        case .saved:
            ModelSettingsStatusPresentation(
                message: "Changes saved",
                symbol: "checkmark.circle.fill",
                tone: .success,
                showsProgress: false
            )
        }
    }
}

struct ModelSettingsStatusPresentation: Equatable {
    let message: String
    let symbol: String?
    let tone: ModelSettingsStatusTone
    let showsProgress: Bool
}

enum ModelSettingsStatusTone: Equatable {
    case secondary
    case success
    case warning
}
