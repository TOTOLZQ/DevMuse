import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MuseStore
    @State private var confirmingReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                appearanceSection
                librarySection
                pipelineSection
                resetSection
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(MuseTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .alert("重置全部数据？", isPresented: $confirmingReset) {
            Button("重置", role: .destructive) {
                store.resetAll()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("本设备上的笔记、片段与提示词将恢复为初始内容。")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("设置")
                .font(MuseFont.mono(10, .semibold))
                .tracking(2.4)
                .foregroundColor(MuseTheme.inkFaint)

            Text("设置")
                .font(MuseFont.serif(30, .semibold))
                .foregroundColor(MuseTheme.ink)

            Text("调整外观、查看资料库，并发布构建。")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)

            MuseHairline()
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MuseSectionLabel(text: "外观")

            VStack(spacing: 0) {
                ForEach(AppAppearance.allCases) { value in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            store.setAppearance(value)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(swatch(for: value))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle().strokeBorder(MuseTheme.hairline, lineWidth: 1)
                                )
                            Text(value.title)
                                .font(MuseFont.sans(14, .medium))
                                .foregroundColor(MuseTheme.ink)
                            Spacer()
                            if store.appearance == value {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(MuseTheme.rust)
                            }
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if value != .system {
                        Rectangle()
                            .fill(MuseTheme.hairline)
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MuseTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MuseTheme.hairline, lineWidth: 1)
            )
        }
    }

    private func swatch(for value: AppAppearance) -> Color {
        switch value {
        case .paper: return Color(red: 0.965, green: 0.949, blue: 0.918)
        case .ink: return Color(red: 0.082, green: 0.075, blue: 0.067)
        case .system: return Color(red: 0.576, green: 0.553, blue: 0.514)
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MuseSectionLabel(text: "资料库")

            HStack(spacing: 12) {
                statBlock(value: store.cards.count, title: "笔记")
                statBlock(value: store.snippets.count, title: "片段")
                statBlock(value: store.prompts.count, title: "提示词")
            }
        }
    }

    private func statBlock(value: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(MuseFont.serif(26, .semibold))
                .foregroundColor(MuseTheme.ink)
            Text(title.uppercased())
                .font(MuseFont.mono(9, .medium))
                .tracking(1.4)
                .foregroundColor(MuseTheme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .museCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(title)")
    }

    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MuseSectionLabel(text: "发布")

            VStack(alignment: .leading, spacing: 12) {
                Text("这个构建如何成为 IPA")
                    .font(MuseFont.serif(18, .semibold))
                    .foregroundColor(MuseTheme.ink)

                pipelineStep(index: "1", text: "把这个仓库推送到 GitHub。")
                pipelineStep(index: "2", text: "运行 Build unsigned IPA 工作流。")
                pipelineStep(index: "3", text: "下载产物，用你自己的签名工具重签。")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .museCard(padding: 16)
        }
    }

    private func pipelineStep(index: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(index)
                .font(MuseFont.mono(10, .semibold))
                .foregroundColor(MuseTheme.rust)
                .frame(width: 16, height: 16)
                .background(
                    Circle().strokeBorder(MuseTheme.rust.opacity(0.4), lineWidth: 1)
                )
            Text(text)
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MuseSectionLabel(text: "数据")

            Button {
                confirmingReset = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("重置为初始内容")
                        .font(MuseFont.sans(14, .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MuseTheme.inkFaint)
                }
                .foregroundColor(MuseTheme.rust)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MuseTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MuseTheme.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            MuseHairline()
            Text("开发助手 1.0")
                .font(MuseFont.mono(10, .medium))
                .foregroundColor(MuseTheme.inkFaint)
            Text("本地优先。无需账号，无网络请求。")
                .font(MuseFont.sans(11))
                .foregroundColor(MuseTheme.inkFaint)
        }
        .padding(.top, 4)
    }
}
