import SwiftUI
import UIKit

struct AgentView: View {
    @EnvironmentObject private var store: MuseStore
    @State private var input = ""
    @State private var isThinking = false
    @State private var task: Task<Void, Never>?
    @FocusState private var focused: Bool

    private let quickPrompts = [
        "Review this diff",
        "Refactor this snippet",
        "Plan the tests",
        "Write a commit message",
        "Draft the release checklist"
    ]

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.messages) { message in
                            bubble(message)
                                .id(message.id)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: message.role == .user ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .opacity
                                    )
                                )
                        }

                        if isThinking {
                            thinkingBubble
                                .id("thinking")
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: store.messages.count) { _ in scrollToBottom(proxy) }
                .onChange(of: isThinking) { _ in scrollToBottom(proxy) }
            }

            if store.messages.count <= 1 {
                quickRow
            }

            inputBar
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { task?.cancel() }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("AGENT")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(MuseSpring.snappy) {
                        store.clearConversation()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MuseTheme.inkSoft)
                }
                .pressable()
                .accessibilityLabel("Clear conversation")
            }
            Text("Development Copilot")
                .font(MuseFont.serif(27, .semibold))
                .foregroundColor(MuseTheme.ink)
            MuseHairline()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MuseTheme.paper)
    }

    private var thinkingBubble: some View {
        HStack {
            assistantAvatar
            VStack(alignment: .leading, spacing: 6) {
                Text("thinking")
                    .font(MuseFont.mono(9, .semibold))
                    .tracking(1.2)
                    .foregroundColor(MuseTheme.inkFaint)
                TypingIndicator()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MuseTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MuseTheme.hairline, lineWidth: 1)
            )
            Spacer(minLength: 60)
        }
        .padding(.trailing, 40)
    }

    private var quickRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        send(prompt)
                    } label: {
                        Text(prompt)
                            .font(MuseFont.sans(13, .medium))
                            .foregroundColor(MuseTheme.inkSoft)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(MuseTheme.surface)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                            )
                    }
                    .pressable()
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask me anything about your code", text: $input)
                .font(MuseFont.sans(15))
                .foregroundColor(MuseTheme.ink)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .submitLabel(.send)
                .onSubmit { send(input) }

            Button {
                send(input)
            } label: {
                ZStack {
                    Circle()
                        .fill(input.trimmingCharacters(in: .whitespaces).isEmpty
                              ? MuseTheme.hairline
                              : MuseTheme.ink)
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(input.trimmingCharacters(in: .whitespaces).isEmpty
                            ? MuseTheme.inkFaint
                            : MuseTheme.paper)
                }
            }
            .pressable(scale: 0.9)
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MuseTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MuseTheme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(MuseTheme.rust.opacity(0.12))
                .frame(width: 26, height: 26)
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(MuseTheme.rust)
        }
    }

    private func bubble(_ message: AgentMessage) -> some View {
        HStack {
            if message.role == .assistant {
                assistantAvatar
                VStack(alignment: .leading, spacing: 6) {
                    assistantContent(message)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MuseTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                )
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.content
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                Text(message.content)
                    .font(MuseFont.sans(15))
                    .foregroundColor(MuseTheme.paper)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(MuseTheme.rust)
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func assistantContent(_ message: AgentMessage) -> some View {
        let shouldStream = shouldStreamMessage(message)
        if shouldStream {
            StreamingText(full: message.content)
                .font(MuseFont.sans(15))
                .foregroundColor(MuseTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            cursor
        } else {
            Text(message.content)
                .font(MuseFont.sans(15))
                .foregroundColor(MuseTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func shouldStreamMessage(_ message: AgentMessage) -> Bool {
        guard message.role == .assistant,
              let last = store.messages.last,
              last.id == message.id else { return false }
        return store.messages.count > 1
    }

    private var cursor: some View {
        Capsule()
            .fill(MuseTheme.rust)
            .frame(width: 7, height: 14)
            .opacity(0.8)
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        store.addUserMessage(trimmed)
        input = ""
        isThinking = true
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            if Task.isCancelled { return }
            let reply = store.response(for: trimmed)
            await MainActor.run {
                store.appendAssistantMessage(reply)
                isThinking = false
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(MuseSpring.soft) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

struct AgentView_Previews: PreviewProvider {
    static var previews: some View {
        AgentView()
            .environmentObject(MuseStore())
    }
}
