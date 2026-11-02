import SwiftUI
import UIKit

private enum TerminalColor {
    static let background = Color(red: 0.075, green: 0.072, blue: 0.067)
    static let bar = Color(red: 0.118, green: 0.112, blue: 0.105)
    static let text = Color(red: 0.914, green: 0.902, blue: 0.878)
    static let dim = Color(red: 0.545, green: 0.522, blue: 0.490)
    static let command = Color(red: 0.620, green: 0.780, blue: 0.880)
    static let accent = Color(red: 0.878, green: 0.478, blue: 0.369)
    static let ok = Color(red: 0.639, green: 0.686, blue: 0.518)
    static let error = Color(red: 0.902, green: 0.435, blue: 0.404)
}

struct SandboxView: View {
    @ObservedObject var shell: SandboxShell
    @State private var input = ""
    @State private var appeared = false
    @State private var blinking = false
    @FocusState private var focused: Bool

    private let quickCommands = ["ls -l", "tree", "cat notes/todo.md", "uname -a", "wc notes/todo.md", "help", "clear"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                terminal
                quickCommandList
                footnote
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("沙盒")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(TerminalColor.ok)
                        .frame(width: 6, height: 6)
                        .opacity(blinking ? 0.35 : 1)
                    Text("运行中")
                        .font(MuseFont.mono(9, .semibold))
                        .tracking(1)
                        .foregroundColor(MuseTheme.inkFaint)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        blinking = true
                    }
                }
            }

            Text("Linux 沙盒")
                .font(MuseFont.serif(30, .semibold))
                .foregroundColor(MuseTheme.ink)

            Text("设备内的虚拟终端。命令只作用于沙盒文件系统，不触碰真实数据。")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            MuseHairline()
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var terminal: some View {
        VStack(spacing: 0) {
            terminalBar
            scrollback
            inputBar
        }
        .background(TerminalColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 10)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    private var terminalBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Circle().fill(Color(red: 0.91, green: 0.42, blue: 0.38)).frame(width: 8, height: 8)
                Circle().fill(Color(red: 0.90, green: 0.72, blue: 0.33)).frame(width: 8, height: 8)
                Circle().fill(Color(red: 0.45, green: 0.72, blue: 0.43)).frame(width: 8, height: 8)
            }
            Text("muse@devmuse")
                .font(MuseFont.mono(10, .medium))
                .foregroundColor(TerminalColor.dim)
            Spacer()
            Text(shell.displayPath)
                .font(MuseFont.mono(10, .medium))
                .foregroundColor(TerminalColor.dim)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeOut(duration: 0.2)) {
                    shell.clear()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(TerminalColor.dim)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("清空终端")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(TerminalColor.bar)
    }

    private var scrollback: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(shell.lines) { line in
                        lineView(line)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("terminal-end")
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 392)
            .onChange(of: shell.lines.count) { _ in
                withAnimation(.easeOut(duration: 0.18)) {
                    proxy.scrollTo("terminal-end", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("terminal-end", anchor: .bottom)
            }
        }
    }

    private func lineView(_ line: TerminalLine) -> some View {
        Text(line.text.isEmpty ? " " : line.text)
            .font(MuseFont.mono(11.5, line.style == .command ? .semibold : .regular))
            .foregroundColor(color(for: line.style))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func color(for style: TerminalLine.Style) -> Color {
        switch style {
        case .command: return TerminalColor.command
        case .output: return TerminalColor.text
        case .error: return TerminalColor.error
        case .info: return TerminalColor.ok
        case .success: return TerminalColor.ok
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(MuseFont.mono(13, .semibold))
                .foregroundColor(TerminalColor.ok)
            ZStack(alignment: .leading) {
                if input.isEmpty {
                    Text("输入命令，例如 ls -l")
                        .font(MuseFont.mono(12))
                        .foregroundColor(TerminalColor.dim)
                        .allowsHitTesting(false)
                }
                TextField("", text: $input)
                    .font(MuseFont.mono(12))
                    .foregroundColor(TerminalColor.text)
                    .tint(TerminalColor.ok)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.send)
                    .focused($focused)
                    .onSubmit { submit() }
            }
            Button {
                submit()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? TerminalColor.dim : TerminalColor.accent)
            }
            .buttonStyle(.plain)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("执行命令")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(TerminalColor.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var quickCommandList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                MuseSectionLabel(text: "快捷命令")
                Spacer()
                Text("\(shell.commandCount) 条历史")
                    .font(MuseFont.mono(9, .medium))
                    .tracking(1)
                    .foregroundColor(MuseTheme.inkFaint)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickCommands, id: \.self) { command in
                        Button {
                            run(command)
                        } label: {
                            MuseChip(text: command, selected: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var footnote: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield")
                .font(.system(size: 10, weight: .semibold))
            Text("全部在本地内存中运行，不联网，也不访问系统文件。")
                .font(MuseFont.sans(11))
        }
        .foregroundColor(MuseTheme.inkFaint)
    }

    private func submit() {
        let command = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        input = ""
        run(command)
    }

    private func run(_ command: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        shell.run(command)
    }
}
