import SwiftUI
import UIKit

struct PromptEditorRoute: Identifiable {
    let id = UUID()
    let prompt: PromptIdea
    let isNew: Bool
}

struct PromptGroup: Identifiable {
    let category: String
    let prompts: [PromptIdea]
    var id: String { category }
}

struct PromptLabView: View {
    @EnvironmentObject private var store: MuseStore
    @State private var editorRoute: PromptEditorRoute?

    private var groups: [PromptGroup] {
        Set(store.prompts.map { $0.category })
            .sorted()
            .map { category in
                PromptGroup(
                    category: category,
                    prompts: store.prompts.filter { $0.category == category }
                )
            }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header

                if store.prompts.isEmpty {
                    emptyState
                } else {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                MuseSectionLabel(text: group.category)
                                Rectangle()
                                    .fill(MuseTheme.hairline)
                                    .frame(height: 1)
                            }
                            ForEach(group.prompts) { prompt in
                                NavigationLink {
                                    PromptDetailView(promptID: prompt.id)
                                } label: {
                                    PromptCard(prompt: prompt)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        editorRoute = PromptEditorRoute(prompt: prompt, isNew: false)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button {
                                        UIPasteboard.general.string = prompt.body
                                    } label: {
                                        Label("Copy prompt", systemImage: "doc.on.doc")
                                    }
                                    Button(role: .destructive) {
                                        store.deletePrompt(prompt.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editorRoute) { route in
            PromptEditorSheet(
                prompt: route.prompt,
                isNew: route.isNew,
                onSave: { prompt in
                    if route.isNew {
                        store.addPrompt(prompt)
                    } else {
                        store.updatePrompt(prompt)
                    }
                },
                onDelete: {
                    if !route.isNew {
                        store.deletePrompt(route.prompt.id)
                    }
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("PROMPTS")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)
                Spacer()
                Button {
                    editorRoute = PromptEditorRoute(
                        prompt: PromptIdea(title: "", category: "Review", body: ""),
                        isNew: true
                    )
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(MuseTheme.paper)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(MuseTheme.ink))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New prompt")
            }

            Text("Prompt Lab")
                .font(MuseFont.serif(30, .semibold))
                .foregroundColor(MuseTheme.ink)

            Text("Reusable instructions for reviews, refactors and releases.")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)

            MuseHairline()
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No prompts yet")
                .font(MuseFont.serif(20, .semibold))
                .foregroundColor(MuseTheme.ink)
            Text("Write the instructions you repeat, then reuse them.")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .museCard(padding: 18)
    }
}

struct PromptCard: View {
    let prompt: PromptIdea

    private var preview: String {
        prompt.body
            .split(separator: "\n", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prompt.title.isEmpty ? "Untitled prompt" : prompt.title)
                .font(MuseFont.serif(19, .semibold))
                .foregroundColor(MuseTheme.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text(preview)
                .font(MuseFont.sans(12.5))
                .foregroundColor(MuseTheme.inkSoft)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.system(size: 9, weight: .semibold))
                Text(prompt.body.count.description + " CHARS")
                    .font(MuseFont.mono(9, .medium))
                    .tracking(1)
            }
            .foregroundColor(MuseTheme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .museCard(padding: 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prompt.title), \(prompt.category) prompt")
    }
}

struct PromptDetailView: View {
    @EnvironmentObject private var store: MuseStore
    @Environment(\.dismiss) private var dismiss
    let promptID: UUID
    @State private var editing = false
    @State private var confirmingDelete = false

    private var prompt: PromptIdea? {
        store.prompts.first { $0.id == promptID }
    }

    var body: some View {
        Group {
            if let prompt = prompt {
                content(prompt)
            } else {
                VStack(spacing: 8) {
                    Text("This prompt is gone")
                        .font(MuseFont.serif(22, .semibold))
                        .foregroundColor(MuseTheme.ink)
                    Text("It was deleted from the lab.")
                        .font(MuseFont.sans(13))
                        .foregroundColor(MuseTheme.inkSoft)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .navigationTitle("Prompt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = true
                } label: {
                    Text("Edit")
                        .font(MuseFont.sans(14, .semibold))
                        .foregroundColor(MuseTheme.rust)
                }
            }
        }
        .sheet(isPresented: $editing) {
            if let prompt = prompt {
                PromptEditorSheet(
                    prompt: prompt,
                    isNew: false,
                    onSave: { updated in
                        store.updatePrompt(updated)
                    },
                    onDelete: {
                        store.deletePrompt(prompt.id)
                        dismiss()
                    }
                )
            }
        }
        .alert("Delete prompt?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                store.deletePrompt(promptID)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes it from the lab on this device.")
        }
    }

    private func content(_ prompt: PromptIdea) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    MuseChip(text: prompt.category, selected: false)
                    Spacer()
                    MuseCopyButton(text: prompt.body)
                }

                Text(prompt.title.isEmpty ? "Untitled prompt" : prompt.title)
                    .font(MuseFont.serif(28, .semibold))
                    .foregroundColor(MuseTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                MuseHairline()

                Text(prompt.body.isEmpty ? "No instructions yet." : prompt.body)
                    .font(MuseFont.serif(16))
                    .foregroundColor(MuseTheme.ink)
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(MuseTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                    )

                HStack {
                    Spacer()
                    Button {
                        confirmingDelete = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Delete")
                                .font(MuseFont.sans(12, .semibold))
                        }
                        .foregroundColor(MuseTheme.rust)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }
}

struct PromptEditorSheet: View {
    let prompt: PromptIdea
    let isNew: Bool
    let onSave: (PromptIdea) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var category: String
    @State private var bodyText: String

    private let categories = ["Review", "Refactor", "Writing", "Ship"]

    init(
        prompt: PromptIdea,
        isNew: Bool,
        onSave: @escaping (PromptIdea) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.prompt = prompt
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: prompt.title)
        _category = State(initialValue: prompt.category)
        _bodyText = State(initialValue: prompt.body)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(isNew ? "NEW PROMPT" : "EDIT PROMPT")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)

                Text(isNew ? "Write an instruction" : "Refine the instruction")
                    .font(MuseFont.serif(28, .semibold))
                    .foregroundColor(MuseTheme.ink)

                MuseHairline()

                MuseSectionLabel(text: "Title")
                TextField("What is it for?", text: $title)
                    .font(MuseFont.serif(18, .semibold))
                    .foregroundColor(MuseTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .overlay(fieldBorder)

                MuseSectionLabel(text: "Category")
                TextField("Category", text: $category)
                    .font(MuseFont.sans(14))
                    .foregroundColor(MuseTheme.ink)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .overlay(fieldBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { value in
                            Button {
                                category = value
                            } label: {
                                MuseChip(text: value, selected: category == value)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                MuseSectionLabel(text: "Instructions")
                TextEditor(text: $bodyText)
                    .font(MuseFont.serif(15))
                    .foregroundColor(MuseTheme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 260)
                    .padding(10)
                    .background(fieldBackground)
                    .overlay(fieldBorder)

                if !isNew {
                    Button(role: .destructive) {
                        onDelete?()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Delete prompt")
                                .font(MuseFont.sans(13, .semibold))
                        }
                        .foregroundColor(MuseTheme.rust)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(MuseFont.sans(14, .semibold))
                        .foregroundColor(MuseTheme.inkSoft)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(MuseTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    save()
                } label: {
                    Text(isNew ? "Save prompt" : "Save")
                        .font(MuseFont.sans(14, .semibold))
                        .foregroundColor(MuseTheme.paper)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(MuseTheme.ink)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(MuseTheme.paper)
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(MuseTheme.surface)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(MuseTheme.hairline, lineWidth: 1)
    }

    private func save() {
        var updated = prompt
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.category = cleanedCategory.isEmpty ? "General" : cleanedCategory
        updated.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(updated)
        dismiss()
    }
}
