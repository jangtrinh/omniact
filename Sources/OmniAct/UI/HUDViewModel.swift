import Foundation
import SwiftUI
import Combine

@MainActor
public final class HUDViewModel: ObservableObject {
    @Published public var inputText: String = "" {
        didSet {
            updateCommandMatching()
            onContentSizeChange?()
        }
    }
    @Published public var selectedText: String = "" {
        didSet { onContentSizeChange?() }
    }
    @Published public var streamedOutput: String = "" {
        didSet { onContentSizeChange?() }
    }
    @Published public var isStreaming: Bool = false {
        didSet { onContentSizeChange?() }
    }
    @Published public var statusMessage: String = ""
    @Published public var matchedCommands: [SlashCommand] = []
    @Published public var selectedCommand: SlashCommand? = nil
    @Published public var config: LLMConfiguration = LLMConfiguration()

    @Published public var errorMessage: String? = nil {
        didSet { onContentSizeChange?() }
    }

    private let commandStore: CommandStore
    private let commandRouter: CommandRouter
    private var commandSubscription: AnyCancellable?
    private var streamTask: Task<Void, Never>?
    public var onDismiss: (() -> Void)?
    public var onAcceptAndReplace: ((String) -> Void)?
    public var onContentSizeChange: (() -> Void)?

    public init(commandStore: CommandStore = .shared, router: CommandRouter? = nil) {
        self.commandStore = commandStore
        self.commandRouter = router ?? CommandRouter(catalog: commandStore)
        loadSavedConfig()
        updateCommandMatching()
        commandSubscription = commandStore.$commands
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.commandCatalogDidChange()
            }
    }

    public func setContext(_ context: AXContext) {
        stopStreaming()
        loadSavedConfig()
        self.selectedText = context.selectedText
        self.inputText = ""
        self.streamedOutput = ""
        self.statusMessage = ""
        self.errorMessage = nil
        self.isStreaming = false
        self.selectedCommand = nil
        updateCommandMatching()
        onContentSizeChange?()
    }

    private func updateCommandMatching() {
        if inputText.hasPrefix("/") {
            matchedCommands = commandRouter.matchCommands(query: inputText)
        } else {
            matchedCommands = commandRouter.commands
        }
    }

    public func selectCommand(_ cmd: SlashCommand) {
        guard let selected = commandRouter.commands.first(where: { $0.id == cmd.id }) else { return }
        self.selectedCommand = selected
        self.inputText = "\(selected.command) "
        execute()
    }

    public func runQuickCommand(_ cmdString: String) {
        self.inputText = cmdString
        self.selectedCommand = commandRouter.resolveCommand(from: cmdString).0
        execute()
    }

    public func execute() {
        guard !isStreaming else { return }

        let liveSelectedCommand = selectedCommand.flatMap { selected in
            commandRouter.commands.first { $0.id == selected.id }
        }
        let cmd = liveSelectedCommand ?? commandRouter.resolveCommand(from: inputText).0
        let (sysPrompt, userPrompt) = commandRouter.buildPrompt(
            command: cmd,
            rawInput: inputText,
            selectedText: selectedText
        )

        if userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.errorMessage = "⚠️ No text selected. Highlight text in any app first, or type: fix <your text>"
            return
        }

        streamedOutput = ""
        errorMessage = nil
        isStreaming = true
        statusMessage = "Generating with \(config.model)..."

        streamTask?.cancel()
        streamTask = Task {
            do {
                let stream = LLMClient.shared.streamCompletion(
                    prompt: userPrompt,
                    systemPrompt: sysPrompt,
                    config: config
                )

                for try await chunk in stream {
                    self.streamedOutput += chunk
                }

                self.isStreaming = false
                self.statusMessage = self.selectedText.isEmpty ? "Ready to insert" : "Ready to replace"
            } catch {
                self.isStreaming = false
                if Task.isCancelled {
                    self.statusMessage = ""
                } else {
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = "Failed"
                }
            }
        }
    }

    public func acceptAndReplace() {
        guard !streamedOutput.isEmpty else { return }
        let textToInsert = streamedOutput
        onAcceptAndReplace?(textToInsert)
    }

    public func cancel() {
        stopStreaming()
        errorMessage = nil
        statusMessage = ""
        onDismiss?()
    }

    public func resetForDismissal() {
        stopStreaming()
        inputText = ""
        streamedOutput = ""
        statusMessage = ""
        errorMessage = nil
        selectedCommand = nil
    }

    public func switchProvider(_ type: LLMProviderType) {
        AppConfig.shared.activeProvider = type
        loadSavedConfig()
        statusMessage = "Switched to \(type.rawValue) (\(config.model))"
    }

    public func loadSavedConfig() {
        self.config = AppConfig.shared.getActiveConfiguration()
    }

    private func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    private func commandCatalogDidChange() {
        if let selected = selectedCommand {
            selectedCommand = commandRouter.commands.first { $0.id == selected.id }
        }
        updateCommandMatching()
        onContentSizeChange?()
    }
}
