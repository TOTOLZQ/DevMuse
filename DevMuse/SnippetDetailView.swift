import SwiftUI
import UIKit

struct SnippetDetailView: View {
    @EnvironmentObject private var store: MuseStore
    @Environment(\.dismiss) private var dismiss
    let snippetID: UUID
    @State private var editing = false
    @State private var confirmingDelete = false

    private var snippet: Snippet? {
        store.snippets.first { $0.id == snippetID }
    }

    var body: some View {
        Group {
            if let snippet = snippet {
                content(snippet)
            } else {
                VStack(spacing: 8) {
                    Text("这个片段已不存在")
                        .font(MuseFont.serif(22, .semibold))
                        .foregroundColor(MuseTheme.ink)
                    Text("它已从代码库中删除。")
                        .font(MuseFont.sans(13))
                        .foregroundColor(MuseTheme.inkSoft)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .navigationTitle("片段")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = true
                } label: {
                    Text("编辑")
                        .font(MuseFont.sans(14, .semibold))
                        .foregroundColor(MuseTheme.rust)
                }
            }
        }
        .sheet(isPresented: $editing) {
            if let snippet = snippet {
                SnippetEditorSheet(
                    snippet: snippet,
                    isNew: false,
                    onSave: { updated in
                        store.updateSnippet(updated)
                    },
                    onDelete: {
                        store.deleteSnippet(snippet.id)
                        dismiss()
                    }
                )
            }
        }
        .alert("删除片段？", isPresented: $confirmingDelete) {
            Button("删除", role: .destructive) {
                store.deleteSnippet(snippetID)
                dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("这会从本机代码库中移除它。")
        }
    }

    private func content(_ snippet: Snippet) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(snippet.language.uppercased())
                        .font(MuseFont.mono(9, .semibold))
                        .tracking(1.2)
                        .foregroundColor(MuseTheme.slate)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(MuseTheme.slate.opacity(0.12))
                        )
                    Spacer()
                    MuseCopyButton(text: snippet.code)
                }

                Text(snippet.title.isEmpty ? "未命名片段" : snippet.title)
                    .font(MuseFont.serif(28, .semibold))
                    .foregroundColor(MuseTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if !snippet.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(snippet.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(MuseFont.mono(10))
                                .foregroundColor(MuseTheme.inkFaint)
                        }
                    }
                }

                MuseHairline()

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(snippet.code.isEmpty ? "还没有代码。" : snippet.code)
                        .font(MuseFont.mono(12.5))
                        .foregroundColor(MuseTheme.ink)
                        .textSelection(.enabled)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MuseTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                )

                HStack(spacing: 10) {
                    Text("保存于 \(snippet.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(MuseFont.mono(10))
                        .foregroundColor(MuseTheme.inkFaint)
                    Spacer()
                    Button {
                        confirmingDelete = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .semibold))
                            Text("删除")
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

struct SnippetEditorSheet: View {
    let snippet: Snippet
    let isNew: Bool
    let onSave: (Snippet) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var language: String
    @State private var tagsText: String
    @State private var code: String

    private let commonLanguages = ["Swift", "Shell", "Python", "TypeScript", "SQL"]

    init(
        snippet: Snippet,
        isNew: Bool,
        onSave: @escaping (Snippet) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.snippet = snippet
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: snippet.title)
        _language = State(initialValue: snippet.language)
        _tagsText = State(initialValue: snippet.tags.joined(separator: ", "))
        _code = State(initialValue: snippet.code)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(isNew ? "新建片段" : "编辑片段")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)

                Text(isNew ? "保存一段代码" : "更新这段代码")
                    .font(MuseFont.serif(28, .semibold))
                    .foregroundColor(MuseTheme.ink)

                MuseHairline()

                MuseSectionLabel(text: "标题")
                TextField("它是做什么的？", text: $title)
                    .font(MuseFont.serif(18, .semibold))
                    .foregroundColor(MuseTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .overlay(fieldBorder)

                MuseSectionLabel(text: "语言")
                TextField("语言", text: $language)
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
                        ForEach(commonLanguages, id: \.self) { value in
                            Button {
                                language = value
                            } label: {
                                MuseChip(text: value, selected: language == value)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                MuseSectionLabel(text: "标签")
                TextField("用逗号分隔", text: $tagsText)
                    .font(MuseFont.sans(14))
                    .foregroundColor(MuseTheme.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .overlay(fieldBorder)

                MuseSectionLabel(text: "代码")
                TextEditor(text: $code)
                    .font(MuseFont.mono(12.5))
                    .foregroundColor(MuseTheme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 240)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
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
                            Text("删除片段")
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
                    Text("取消")
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
                    Text(isNew ? "保存片段" : "保存")
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
        var updated = snippet
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLanguage = language.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.language = cleanedLanguage.isEmpty ? "代码" : cleanedLanguage
        updated.code = code
        updated.tags = tagsText
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        onSave(updated)
        dismiss()
    }
}
