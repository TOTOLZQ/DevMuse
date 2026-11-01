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
                                        Label("编辑", systemImage: "pencil")
                                    }
                                    Button {
                                        UIPasteboard.general.string = prompt.body
                                    } label: {
                                        Label("复制提示词", systemImage: "doc.on.doc")
                                    }
                                    Button(role: .destructive) {
                                        store.deletePrompt(prompt.id)
                                    } label: {
                                        Label("删除", systemImage: "trash")
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
                Text("提示词")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)
                Spacer()
                Button {
                    editorRoute = PromptEditorRoute(
                        prompt: PromptIdea(title: "", category: "审查", body: ""),
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
                .accessibilityLabel("新建提示词")
            }

            Text("提示词实验室")
                .font(MuseFont.serif(30, .semibold))
                .foregroundColor(MuseTheme.ink)

            Text("可复用的指令，用于审查、重构与发布。")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)

            MuseHairline()
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("还没有提示词")
                .font(MuseFont.serif(20, .semibold))
                .foregroundColor(MuseTheme.ink)
            Text("写下你反复使用的指令，然后复用它们。")
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
            Text(prompt.title.isEmpty ? "未命名提示词" : prompt.title)
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
                Text(prompt.body.count.description + " 字")
                    .font(MuseFont.mono(9, .medium))
                    .tracking(1)
            }
            .foregroundColor(MuseTheme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .museCard(padding: 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prompt.title)，\(prompt.category) 提示词")
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
                    Text("此提示词已不存在")
                        .font(MuseFont.serif(22, .semibold))
                        .foregroundColor(MuseTheme.ink)
                    Text("它已从实验室中删除。")
                        .font(MuseFont.sans(13))
                        .foregroundColor(MuseTheme.inkSoft)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .navigationTitle("提示词")
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
        .alert("删除提示词？", isPresented: $confirmingDelete) {
            Button("删除", role: .destructive) {
                store.deletePrompt(promptID)
                dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("这会把它从本设备的实验室中移除。")
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

                Text(prompt.title.isEmpty ? "未命名提示词" : prompt.title)
                    .font(MuseFont.serif(28, .semibold))
                    .foregroundColor(MuseTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                MuseHairline()

                Text(prompt.body.isEmpty ? "还没有指令。" : prompt.body)
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

struct PromptEditorSheet: View {
    let prompt: PromptIdea
    let isNew: Bool
    let onSave: (PromptIdea) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var category: String
    @State private var bodyText: String

    private let categories = ["审查", "重构", "写作", "发布"]

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
                Text(isNew ? "新建提示词" : "编辑提示词")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)

                Text(isNew ? "写下一条指令" : "完善这条指令")
                    .font(MuseFont.serif(28, .semibold))
                    .foregroundColor(MuseTheme.ink)

                MuseHairline()

                MuseSectionLabel(text: "标题")
                TextField("用途是什么？", text: $title)
                    .font(MuseFont.serif(18, .semibold))
                    .foregroundColor(MuseTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .overlay(fieldBorder)

                MuseSectionLabel(text: "分类")
                TextField("分类", text: $category)
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

                MuseSectionLabel(text: "指令内容")
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
                            Text("删除提示词")
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
                    Text(isNew ? "保存提示词" : "保存")
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
        updated.category = cleanedCategory.isEmpty ? "通用" : cleanedCategory
        updated.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(updated)
        dismiss()
    }
}
