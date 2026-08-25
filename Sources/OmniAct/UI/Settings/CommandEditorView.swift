import SwiftUI

struct CommandEditorView: View {
    @ObservedObject var model: CommandLibraryViewModel
    let draft: SlashCommand

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(model.editingID == nil ? "Add Command" : "Edit Command")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(model.originState(for: draft)).font(.system(size: 11)).foregroundColor(.secondary)
            }
            basicFields
            promptFields
            validationMessages
            HStack {
                Button("Cancel") { model.cancelEditing() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel("Cancel command changes")
                Spacer()
                Button("Save") { model.saveDraft() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityLabel("Save command")
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.045))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
    }

    private var basicFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelledField("Slash command", placeholder: "/my-command", keyPath: \.command)
            labelledField("Aliases (comma-separated)", placeholder: "rewrite, polish", aliases: true)
            labelledField("Title", placeholder: "My command", keyPath: \.title)
            labelledField("Description", placeholder: "What this command does", keyPath: \.description)
            HStack(spacing: 12) {
                labelledField("SF Symbol icon", placeholder: "sparkles", keyPath: \.icon)
                Toggle("Enabled", isOn: boolBinding(\.enabled)).font(.system(size: 12, weight: .medium))
            }
        }
    }

    private var promptFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System prompt").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            TextEditor(text: stringBinding(\.systemPrompt))
                .font(.system(size: 11.5))
                .frame(minHeight: 70, maxHeight: 100)
                .padding(4)
                .background(Color.black.opacity(0.12))
                .cornerRadius(6)
                .accessibilityLabel("System prompt")
                .accessibilityHint("Use {text} for selected or typed text and {arg} for the command argument")
            Text("Prompt template — placeholders: {text}, {arg}")
                .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            TextEditor(text: stringBinding(\.promptTemplate))
                .font(.system(size: 11.5, design: .monospaced))
                .frame(minHeight: 60, maxHeight: 90)
                .padding(4)
                .background(Color.black.opacity(0.12))
                .cornerRadius(6)
                .accessibilityLabel("Prompt template")
                .accessibilityHint("Use {text} for selected or typed text and {arg} for the command argument")
        }
    }

    @ViewBuilder
    private var validationMessages: some View {
        if !model.validationIssues.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Fix before saving").font(.system(size: 11, weight: .semibold)).foregroundColor(.orange)
                    Spacer()
                    Button("Clear errors") { model.clearValidationErrors() }.font(.system(size: 10.5))
                }
                ForEach(model.validationIssues, id: \.self) { issue in
                    Text("• \(issue.errorDescription ?? "Invalid command")").font(.system(size: 10.5)).foregroundColor(.orange)
                }
            }
            .padding(8)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(6)
        }
    }

    private func labelledField(
        _ title: String,
        placeholder: String,
        keyPath: WritableKeyPath<SlashCommand, String>? = nil,
        aliases: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 11.5, weight: .medium)).foregroundColor(.secondary)
            TextField(placeholder, text: aliases ? aliasesBinding : stringBinding(keyPath!))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .accessibilityLabel(title)
        }
    }

    private var aliasesBinding: Binding<String> {
        Binding(get: { draft.displayAliases }, set: { model.setAliases($0) })
    }

    private func stringBinding(_ keyPath: WritableKeyPath<SlashCommand, String>) -> Binding<String> {
        Binding(get: { model.draft?[keyPath: keyPath] ?? "" }, set: { value in
            model.updateDraft { $0[keyPath: keyPath] = value }
        })
    }

    private func boolBinding(_ keyPath: WritableKeyPath<SlashCommand, Bool>) -> Binding<Bool> {
        Binding(get: { model.draft?[keyPath: keyPath] ?? false }, set: { value in
            model.updateDraft { $0[keyPath: keyPath] = value }
        })
    }
}
