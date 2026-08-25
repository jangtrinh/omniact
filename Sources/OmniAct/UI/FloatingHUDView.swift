import AppKit
import SwiftUI

public struct FloatingHUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    @FocusState private var isInputFocused: Bool

    public init(viewModel: HUDViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            inputBar
            selectedTextPreview
            streamingDivider
            autocomplete
            quickActions
            errorBanner
            outputArea
            footer
        }
        .frame(width: 540)
        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.30), radius: 18, x: 0, y: 8)
        .fixedSize(horizontal: true, vertical: true)
        .onAppear { isInputFocused = true }
        .onExitCommand { viewModel.cancel() }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            TextField(inputPlaceholder, text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .focused($isInputFocused)
                .onSubmit { viewModel.submitCurrentInput() }
                .onMoveCommand(perform: handleMoveCommand)
                .accessibilityLabel("OmniAct prompt")
                .accessibilityHint("Type a slash command for keyboard-navigable suggestions")

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text(cleanModelName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .accessibilityLabel("Active model")
            .accessibilityValue(cleanModelName)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var selectedTextPreview: some View {
        if !viewModel.selectedText.isEmpty && viewModel.streamedOutput.isEmpty && !viewModel.isStreaming {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                Text(previewSelectedText)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.cyan.opacity(0.08))
            .cornerRadius(6)
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
            .accessibilityLabel("Selected text")
            .accessibilityValue(viewModel.selectedText)
        }
    }

    private var streamingDivider: some View {
        Group {
            if viewModel.isStreaming {
                ProgressView().progressViewStyle(.linear).frame(height: 1.5)
            } else {
                Divider().opacity(0.3)
            }
        }
    }

    @ViewBuilder
    private var autocomplete: some View {
        if shouldShowAutocomplete {
            HUDCommandAutocompleteList(
                commands: viewModel.matchedCommands,
                selectedIndex: viewModel.autocompleteSelectionIndex,
                selectCommand: viewModel.selectCommand
            )
        }
    }

    @ViewBuilder
    private var quickActions: some View {
        if viewModel.streamedOutput.isEmpty && !viewModel.isStreaming && viewModel.errorMessage == nil {
            HUDQuickActionsView(actions: viewModel.quickActions, runAction: viewModel.runQuickAction)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            HUDErrorBanner(error: error)
        }
    }

    @ViewBuilder
    private var outputArea: some View {
        if !viewModel.streamedOutput.isEmpty || viewModel.isStreaming {
            HUDOutputView(output: viewModel.streamedOutput, isStreaming: viewModel.isStreaming)
            Divider().opacity(0.3)
        }
    }

    private var footer: some View {
        HUDFooter(
            statusMessage: viewModel.statusMessage,
            output: viewModel.streamedOutput,
            isStreaming: viewModel.isStreaming,
            replace: viewModel.acceptAndReplace,
            copy: copyOutput,
            close: viewModel.cancel
        )
    }

    private var shouldShowAutocomplete: Bool {
        viewModel.inputText.hasPrefix("/") &&
            !viewModel.matchedCommands.isEmpty &&
            viewModel.streamedOutput.isEmpty &&
            !viewModel.isStreaming
    }

    private var inputPlaceholder: String {
        viewModel.selectedText.isEmpty
            ? "Ask AI or type /fix, /tone, /translate..."
            : "Transform selected text (\(viewModel.selectedText.count) chars)..."
    }

    private var cleanModelName: String {
        viewModel.config.model.components(separatedBy: "/").last ?? viewModel.config.model
    }

    private var previewSelectedText: String {
        let trimmed = viewModel.selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 50 ? "“\(trimmed.prefix(47))…”" : "“\(trimmed)”"
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        switch direction {
        case .up:
            viewModel.moveAutocompleteSelection(.up)
        case .down:
            viewModel.moveAutocompleteSelection(.down)
        default:
            break
        }
    }

    private func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(viewModel.streamedOutput, forType: .string)
        viewModel.statusMessage = "Copied!"
    }
}
