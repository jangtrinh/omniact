import SwiftUI

struct HUDCommandAutocompleteList: View {
    private static let rowHeight: CGFloat = 42

    let commands: [SlashCommand]
    let selectedIndex: Int?
    let selectCommand: (SlashCommand) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Command suggestions")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 7)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(commands.enumerated()), id: \.element.id) { index, command in
                            suggestionRow(command, at: index)
                                .id(command.id)
                        }
                    }
                }
                .frame(height: viewportHeight)
                .onAppear { scrollToSelection(using: proxy) }
                .onChange(of: selectedStableID, initial: true) { _, _ in
                    scrollToSelection(using: proxy)
                }
            }
        }
        .padding(.bottom, 6)
        .background(Color.white.opacity(0.035))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Command suggestions")
    }

    private var viewportHeight: CGFloat {
        CGFloat(HUDAutocompleteViewport.visibleRowCount(for: commands.count)) * Self.rowHeight
    }

    private var selectedStableID: String? {
        HUDAutocompleteViewport.selectedStableID(commands: commands, selectedIndex: selectedIndex)
    }

    private func scrollToSelection(using proxy: ScrollViewProxy) {
        guard let selectedStableID else { return }
        withAnimation(.easeOut(duration: 0.12)) {
            proxy.scrollTo(selectedStableID, anchor: .center)
        }
    }

    private func suggestionRow(_ command: SlashCommand, at index: Int) -> some View {
        let isSelected = selectedIndex == index
        return Button {
            selectCommand(command)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: command.icon)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(command.command)  \(command.title)")
                        .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                    if !command.description.isEmpty {
                        Text(command.description)
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if isSelected {
                    Text("↵")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white.opacity(isSelected ? 0.14 : 0.0))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .frame(minHeight: Self.rowHeight)
        .accessibilityLabel("\(command.title), \(command.command)")
        .accessibilityValue(isSelected ? "Selected suggestion \(index + 1) of \(commands.count)" : "Suggestion \(index + 1) of \(commands.count)")
        .accessibilityHint("Selects and runs this command")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilitySortPriority(Double(commands.count - index))
    }
}
