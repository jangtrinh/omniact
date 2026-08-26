import SwiftUI

struct CommandEditorView: View {
    @ObservedObject var model: CommandLibraryViewModel
    let draft: SlashCommand

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            basicFields
            promptFields
            validationMessages
            HStack {
                Text(model.originState(for: draft))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { model.cancelEditing() }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel("Cancel command changes")
                Button("Save") { model.saveDraft() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityLabel("Save command")
            }
        }
        .padding(.vertical, 4)
    }

    private var basicFields: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            labelledField("Slash command", placeholder: "/my-command", keyPath: \.command)
            labelledField("Aliases", placeholder: "rewrite, polish", aliases: true)
            labelledField("Title", placeholder: "My command", keyPath: \.title)
            labelledField("Description", placeholder: "What this command does", keyPath: \.description)
            labelledField("SF Symbol", placeholder: "sparkles", keyPath: \.icon)
            GridRow {
                Text("Enabled")
                Toggle("Enabled", isOn: boolBinding(\.enabled)).labelsHidden()
            }
        }
    }

    private var promptFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System prompt").foregroundStyle(.secondary)
            TextEditor(text: stringBinding(\.systemPrompt))
                .frame(minHeight: 70, maxHeight: 100)
                .font(.body)
                .accessibilityLabel("System prompt")
                .accessibilityHint("Use {text} for input and {arg} for the command argument")
            Text("Prompt template — placeholders: {text}, {arg}")
                .foregroundStyle(.secondary)
            TextEditor(text: stringBinding(\.promptTemplate))
                .frame(minHeight: 60, maxHeight: 90)
                .font(.body.monospaced())
                .accessibilityLabel("Prompt template")
                .accessibilityHint("Use {text} for input and {arg} for the command argument")
        }
    }

    @ViewBuilder
    private var validationMessages: some View {
        if !model.validationIssues.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Fix before saving", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Clear Errors") { model.clearValidationErrors() }
                }
                ForEach(model.validationIssues, id: \.self) { issue in
                    Text(issue.errorDescription ?? "Invalid command")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func labelledField(
        _ title: String,
        placeholder: String,
        keyPath: WritableKeyPath<SlashCommand, String>? = nil,
        aliases: Bool = false
    ) -> some View {
        GridRow {
            Text(title)
            TextField(placeholder, text: aliases ? aliasesBinding : stringBinding(keyPath!))
                .textFieldStyle(.roundedBorder)
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
