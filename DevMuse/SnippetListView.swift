import SwiftUI
import UIKit

struct SnippetEditorRoute: Identifiable {
    let id = UUID()
    let snippet: Snippet
    let isNew: Bool
}

struct SnippetListView: View {
    @EnvironmentObject private var store: MuseStore
    @State private var query = ""
    @State private var activeLanguage: String?
    @State private var editorRoute: SnippetEditorRoute?

    private var languages: [String] {
        Array(Set(store.snippets.map { $0.language })).sorted()
    }

    private var filtered: [Snippet] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.snippets.filter { snippet in
            let matchesLanguage = activeLanguage == nil || snippet.language == activeLanguage
            guard matchesLanguage else { return false }
            guard !trimmed.isEmpty else { return true }
            return snippet.title.localizedCaseInsensitiveContains(trimmed)
                || snippet.code.localizedCaseInsensitiveContains(trimmed)
                || snippet.language.localizedCaseInsensitiveContains(trimmed)
                || snippet.tags.joined(separator: " ").localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                header

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            activeLanguage = nil
                        } label: {
                            MuseChip(text: "All", selected: activeLanguage == nil)
                        }
                        .buttonStyle(.plain)

                        ForEach(languages, id: \.self) { language in
                            Button {
                                activeLanguage = language
                            } label: {
                                MuseChip(text: language, selected: activeLanguage == language)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(filtered) { snippet in
                        NavigationLink {
                            SnippetDetailView(snippetID: snippet.id)
                        } label: {
                            SnippetRow(snippet: snippet)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                editorRoute = SnippetEditorRoute(snippet: snippet, isNew: false)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button {
                                UIPasteboard.general.string = snippet.code
                            } label: {
                                Label("Copy code", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                store.deleteSnippet(snippet.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
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
            SnippetEditorSheet(
                snippet: route.snippet,
                isNew: route.isNew,
                onSave: { snippet in
                    if route.isNew {
                        store.addSnippet(snippet)
                    } else {
                        store.updateSnippet(snippet)
                    }
                },
                onDelete: {
                    if !route.isNew {
                        store.deleteSnippet(route.snippet.id)
                    }
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("VAULT")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)
                Spacer()
                Button {
                    editorRoute = SnippetEditorRoute(
                        snippet: Snippet(title: "", language: "Swift", code: "", tags: []),
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
                .accessibilityLabel("New snippet")
            }

            Text("Snippet Vault")
                .font(MuseFont.serif(30, .semibold))
                .foregroundColor(MuseTheme.ink)

            Text("Code you keep reaching for, one tap away.")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)

            MuseSearchField(text: $query, placeholder: "Search title, code or tag")
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(query.isEmpty ? "Nothing saved yet" : "No matches")
                .font(MuseFont.serif(20, .semibold))
                .foregroundColor(MuseTheme.ink)
            Text(query.isEmpty ? "Save the commands you retype the most." : "Try another keyword or clear the filter.")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .museCard(padding: 18)
    }
}

struct SnippetRow: View {
    let snippet: Snippet

    private var preview: String {
        snippet.code
            .split(separator: "\n", omittingEmptySubsequences: false)
            .prefix(3)
            .joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MuseTheme.inkFaint)
            }

            Text(snippet.title.isEmpty ? "Untitled snippet" : snippet.title)
                .font(MuseFont.serif(19, .semibold))
                .foregroundColor(MuseTheme.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            if !snippet.code.isEmpty {
                Text(preview)
                    .font(MuseFont.mono(11))
                    .foregroundColor(MuseTheme.inkSoft)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }

            if !snippet.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(snippet.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(MuseFont.mono(9))
                            .foregroundColor(MuseTheme.inkFaint)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .museCard(padding: 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snippet.title), \(snippet.language) snippet")
    }
}
