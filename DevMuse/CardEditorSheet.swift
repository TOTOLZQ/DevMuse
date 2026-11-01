import SwiftUI

struct CardEditorSheet: View {
    let card: NoteCard
    let isNew: Bool
    let onSave: (NoteCard) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var bodyText: String
    @State private var kind: CardKind

    init(
        card: NoteCard,
        isNew: Bool,
        onSave: @escaping (NoteCard) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.card = card
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: card.title)
        _bodyText = State(initialValue: card.body)
        _kind = State(initialValue: card.kind)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(isNew ? "新建笔记" : "编辑笔记")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)

                Text(isNew ? "写下一个想法" : "打磨这个想法")
                    .font(MuseFont.serif(28, .semibold))
                    .foregroundColor(MuseTheme.ink)

                MuseHairline()

                MuseSectionLabel(text: "类型")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CardKind.allCases) { value in
                            Button {
                                kind = value
                            } label: {
                                MuseChip(text: value.label, selected: kind == value)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                MuseSectionLabel(text: "标题")
                TextField("一句话说清", text: $title)
                    .font(MuseFont.serif(19, .semibold))
                    .foregroundColor(MuseTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MuseTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                    )

                MuseSectionLabel(text: "详情")
                TextEditor(text: $bodyText)
                    .font(MuseFont.sans(14))
                    .foregroundColor(MuseTheme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MuseTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                    )

                if !isNew {
                    Button(role: .destructive) {
                        onDelete?()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                            Text("删除笔记")
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
        .presentationDetents([.medium, .large])
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
                    Text(isNew ? "放到画布" : "保存")
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

    private func save() {
        var updated = card
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.kind = kind
        onSave(updated)
        dismiss()
    }
}
