import SwiftUI

public struct FloatingHUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    @FocusState private var isInputFocused: Bool
    @State private var hoveredAction: String? = nil

    public init(viewModel: HUDViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. Search / Prompt Bar
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                TextField(
                    viewModel.selectedText.isEmpty
                        ? "Ask AI or type /fix, /tone, /translate..."
                        : "Transform selected text (\(viewModel.selectedText.count) chars)...",
                    text: $viewModel.inputText
                )
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .focused($isInputFocused)
                .onSubmit {
                    if !viewModel.streamedOutput.isEmpty && !viewModel.isStreaming {
                        viewModel.acceptAndReplace()
                    } else {
                        viewModel.execute()
                    }
                }

                // Model Badge
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
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // MARK: - Context Quote (If text is selected)
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
            }

            // Streaming Indicator
            if viewModel.isStreaming {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(height: 1.5)
            } else {
                Divider()
                    .opacity(0.3)
            }

            // MARK: - 2. Quick Action Pills (1-Row Native Capsules)
            if viewModel.streamedOutput.isEmpty && !viewModel.isStreaming && viewModel.errorMessage == nil {
                HStack(spacing: 6) {
                    NativeActionPill(
                        title: "Fix Grammar",
                        icon: "wand.and.stars",
                        isHovered: hoveredAction == "fix"
                    ) {
                        viewModel.runQuickCommand("/fix")
                    }
                    .onHover { isHovered in hoveredAction = isHovered ? "fix" : nil }

                    NativeActionPill(
                        title: "Professional",
                        icon: "briefcase",
                        isHovered: hoveredAction == "tone"
                    ) {
                        viewModel.runQuickCommand("/tone formal")
                    }
                    .onHover { isHovered in hoveredAction = isHovered ? "tone" : nil }

                    NativeActionPill(
                        title: "Translate VI",
                        icon: "globe",
                        isHovered: hoveredAction == "translate"
                    ) {
                        viewModel.runQuickCommand("/translate vi")
                    }
                    .onHover { isHovered in hoveredAction = isHovered ? "translate" : nil }

                    NativeActionPill(
                        title: "Summarize",
                        icon: "list.bullet",
                        isHovered: hoveredAction == "summarize"
                    ) {
                        viewModel.runQuickCommand("/summarize")
                    }
                    .onHover { isHovered in hoveredAction = isHovered ? "summarize" : nil }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            // MARK: - 3. Error Banner
            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(10)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            // MARK: - 4. Streamed Output Area (Auto-Layout, No Cropping)
            if !viewModel.streamedOutput.isEmpty || viewModel.isStreaming {
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        Text(viewModel.streamedOutput.isEmpty ? "Generating..." : viewModel.streamedOutput)
                            .font(.system(size: 13.5))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 44, maxHeight: 220)
                }
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Divider()
                    .opacity(0.3)
            }

            // MARK: - 5. Minimalist Footer
            HStack {
                Text(viewModel.statusMessage.isEmpty ? "Ready" : viewModel.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 6) {
                    if !viewModel.streamedOutput.isEmpty && !viewModel.isStreaming {
                        NativeKeyBadge(key: "↵", label: "Replace") {
                            viewModel.acceptAndReplace()
                        }
                        NativeKeyBadge(key: "⌘C", label: "Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(viewModel.streamedOutput, forType: .string)
                            viewModel.statusMessage = "Copied!"
                        }
                    }
                    NativeKeyBadge(key: "Esc", label: "Close") {
                        viewModel.cancel()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))
        }
        .frame(width: 540)
        // MARK: - Native macOS Glass Material
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.30), radius: 18, x: 0, y: 8)
        .fixedSize(horizontal: true, vertical: true)
        .onAppear {
            isInputFocused = true
        }
    }

    private var cleanModelName: String {
        let model = viewModel.config.model
        if model.contains("/") {
            return model.components(separatedBy: "/").last ?? model
        }
        return model
    }

    private var previewSelectedText: String {
        let trimmed = viewModel.selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 50 {
            return "“\(trimmed.prefix(47))…”"
        }
        return "“\(trimmed)”"
    }
}

// MARK: - NativeActionPill
struct NativeActionPill: View {
    let title: String
    let icon: String
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(isHovered ? 0.16 : 0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(isHovered ? 0.28 : 0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NativeKeyBadge
struct NativeKeyBadge: View {
    let key: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Text(key)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(3.5)

                Text(label)
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background(Color.white.opacity(0.04))
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}
