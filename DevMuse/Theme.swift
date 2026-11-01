import SwiftUI
import UIKit

private func museColor(_ light: UIColor, _ dark: UIColor) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? dark : light
    })
}

enum MuseTheme {
    static let paper = museColor(
        UIColor(red: 0.965, green: 0.949, blue: 0.918, alpha: 1),
        UIColor(red: 0.082, green: 0.075, blue: 0.067, alpha: 1)
    )
    static let paperDeep = museColor(
        UIColor(red: 0.929, green: 0.910, blue: 0.871, alpha: 1),
        UIColor(red: 0.055, green: 0.051, blue: 0.047, alpha: 1)
    )
    static let surface = museColor(
        UIColor(red: 0.992, green: 0.984, blue: 0.969, alpha: 1),
        UIColor(red: 0.125, green: 0.118, blue: 0.110, alpha: 1)
    )
    static let ink = museColor(
        UIColor(red: 0.129, green: 0.118, blue: 0.102, alpha: 1),
        UIColor(red: 0.945, green: 0.933, blue: 0.914, alpha: 1)
    )
    static let inkSoft = museColor(
        UIColor(red: 0.357, green: 0.337, blue: 0.306, alpha: 1),
        UIColor(red: 0.741, green: 0.722, blue: 0.690, alpha: 1)
    )
    static let inkFaint = museColor(
        UIColor(red: 0.576, green: 0.553, blue: 0.514, alpha: 1),
        UIColor(red: 0.529, green: 0.510, blue: 0.482, alpha: 1)
    )
    static let hairline = museColor(
        UIColor(red: 0.843, green: 0.820, blue: 0.776, alpha: 1),
        UIColor(red: 0.235, green: 0.224, blue: 0.208, alpha: 1)
    )
    static let dot = museColor(
        UIColor(red: 0.129, green: 0.118, blue: 0.102, alpha: 0.18),
        UIColor(red: 0.945, green: 0.933, blue: 0.914, alpha: 0.12)
    )
    static let rust = museColor(
        UIColor(red: 0.706, green: 0.286, blue: 0.192, alpha: 1),
        UIColor(red: 0.878, green: 0.478, blue: 0.369, alpha: 1)
    )
    static let olive = museColor(
        UIColor(red: 0.404, green: 0.451, blue: 0.318, alpha: 1),
        UIColor(red: 0.639, green: 0.686, blue: 0.518, alpha: 1)
    )
    static let slate = museColor(
        UIColor(red: 0.263, green: 0.361, blue: 0.435, alpha: 1),
        UIColor(red: 0.518, green: 0.647, blue: 0.745, alpha: 1)
    )
    static let gold = museColor(
        UIColor(red: 0.639, green: 0.494, blue: 0.243, alpha: 1),
        UIColor(red: 0.839, green: 0.686, blue: 0.392, alpha: 1)
    )
    static let shadow = Color.black.opacity(0.07)
}

enum MuseFont {
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

extension CardKind {
    var label: String {
        switch self {
        case .idea: return "想法"
        case .question: return "疑问"
        case .reference: return "参考"
        case .task: return "任务"
        }
    }

    var symbol: String {
        switch self {
        case .idea: return "lightbulb"
        case .question: return "questionmark.circle"
        case .reference: return "book.closed"
        case .task: return "checklist"
        }
    }

    var tint: Color {
        switch self {
        case .idea: return MuseTheme.gold
        case .question: return MuseTheme.slate
        case .reference: return MuseTheme.olive
        case .task: return MuseTheme.rust
        }
    }
}

extension AppAppearance {
    var title: String {
        switch self {
        case .paper: return "暖纸"
        case .ink: return "墨色"
        case .system: return "跟随系统"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .paper: return .light
        case .ink: return .dark
        case .system: return nil
        }
    }
}

struct MuseHairline: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(MuseTheme.hairline)
                .frame(height: 1)
            Circle()
                .fill(MuseTheme.rust)
                .frame(width: 4, height: 4)
        }
        .accessibilityHidden(true)
    }
}

struct MuseHeader: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(MuseFont.mono(10, .semibold))
                .tracking(2.4)
                .foregroundColor(MuseTheme.inkFaint)
            Text(title)
                .font(MuseFont.serif(32, .semibold))
                .foregroundColor(MuseTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            MuseHairline()
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct MuseChip: View {
    let text: String
    let selected: Bool

    var body: some View {
        Text(text)
            .font(MuseFont.mono(11, .medium))
            .foregroundColor(selected ? MuseTheme.paper : MuseTheme.inkSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selected ? MuseTheme.ink : MuseTheme.surface)
            )
            .overlay(
                Capsule()
                    .strokeBorder(selected ? Color.clear : MuseTheme.hairline, lineWidth: 1)
            )
    }
}

struct MuseCardSurface: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MuseTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MuseTheme.hairline, lineWidth: 1)
            )
            .shadow(color: MuseTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

extension View {
    func museCard(padding: CGFloat = 16) -> some View {
        modifier(MuseCardSurface(padding: padding))
    }
}

struct MuseSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(MuseFont.mono(10, .semibold))
            .tracking(1.8)
            .foregroundColor(MuseTheme.inkFaint)
    }
}

struct MusePrimaryButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(MuseFont.sans(14, .semibold))
            }
            .foregroundColor(MuseTheme.paper)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(MuseTheme.ink))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct MuseSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MuseTheme.inkFaint)
            TextField(placeholder, text: $text)
                .font(MuseFont.sans(14))
                .foregroundColor(MuseTheme.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(MuseTheme.inkFaint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除搜索")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MuseTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MuseTheme.hairline, lineWidth: 1)
        )
    }
}

struct MuseCopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                copied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    copied = false
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                Text(copied ? "已复制" : "复制")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(1.2)
            }
            .foregroundColor(copied ? MuseTheme.paper : MuseTheme.inkSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(copied ? MuseTheme.olive : MuseTheme.surface)
            )
            .overlay(
                Capsule()
                    .strokeBorder(copied ? Color.clear : MuseTheme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "已复制" : "复制到剪贴板")
    }
}

struct DotGrid: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 30
            var path = Path()
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                    x += step
                }
                y += step
            }
            context.fill(path, with: .color(MuseTheme.dot))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum MuseSpring {
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let soft = Animation.spring(response: 0.42, dampingFraction: 0.82)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.72)
}

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var opacity: Double = 1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(MuseSpring.snappy, value: configuration.isPressed)
    }
}

struct TypingIndicator: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(MuseTheme.inkFaint)
                    .frame(width: 6, height: 6)
                    .scaleEffect(0.4 + 0.6 * abs(sin(phase + Double(index) * 0.9)))
            }
        }
        .frame(width: 30, height: 14)
        .onAppear {
            withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .accessibilityLabel("思考中")
    }
}

struct StreamingText: View {
    let full: String
    @State private var shown = 0
    @State private var task: Task<Void, Never>?

    var body: some View {
        Text(String(full.prefix(shown)))
            .onAppear { start() }
            .onChange(of: full) { _ in
                shown = 0
                start()
            }
            .onDisappear { task?.cancel() }
    }

    private func start() {
        task?.cancel()
        shown = 0
        let total = full.count
        guard total > 0 else { return }
        task = Task {
            let step = max(1, total / 220)
            var i = 0
            while i < total {
                try? await Task.sleep(nanoseconds: 12_000_000)
                if Task.isCancelled { return }
                i = min(total, i + step)
                await MainActor.run { shown = i }
            }
        }
    }
}

extension View {
    func pressable(scale: CGFloat = 0.96) -> some View {
        buttonStyle(PressableButtonStyle(scale: scale))
    }
}
