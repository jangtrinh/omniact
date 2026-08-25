import AppKit
import SwiftUI

struct HUDErrorBanner: View {
    let error: String

    var body: some View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Command error")
        .accessibilityValue(error)
    }
}

struct HUDOutputView: View {
    let output: String
    let isStreaming: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                Text(output.isEmpty ? "Generating..." : output)
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
        .accessibilityLabel(isStreaming ? "Generating response" : "Generated response")
    }
}

struct HUDFooter: View {
    let statusMessage: String
    let output: String
    let isStreaming: Bool
    let replace: () -> Void
    let copy: () -> Void
    let close: () -> Void

    var body: some View {
        HStack {
            Text(statusMessage.isEmpty ? "Ready" : statusMessage)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .accessibilityLabel("Status")
                .accessibilityValue(statusMessage.isEmpty ? "Ready" : statusMessage)

            Spacer()

            HStack(spacing: 6) {
                if !output.isEmpty && !isStreaming {
                    NativeKeyBadge(key: "↵", label: "Replace", action: replace)
                    NativeKeyBadge(key: "⌘C", label: "Copy", action: copy)
                }
                NativeKeyBadge(key: "Esc", label: "Close", action: close)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
    }
}

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
        .accessibilityLabel(label)
        .accessibilityValue(key)
    }
}
