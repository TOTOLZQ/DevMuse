import SwiftUI

struct RootTab: Identifiable {
    let id: Int
    let title: String
    let symbol: String
}

struct RootView: View {
    @EnvironmentObject private var store: MuseStore
    @StateObject private var sandbox = SandboxShell()
    @State private var selection = 0

    private let tabs: [RootTab] = [
        RootTab(id: 0, title: "助手", symbol: "sparkles"),
        RootTab(id: 1, title: "画布", symbol: "square.grid.2x2"),
        RootTab(id: 2, title: "沙盒", symbol: "terminal"),
        RootTab(id: 3, title: "代码库", symbol: "curlybraces"),
        RootTab(id: 4, title: "提示词", symbol: "text.quote"),
        RootTab(id: 5, title: "设置", symbol: "slider.horizontal.3")
    ]

    var body: some View {
        VStack(spacing: 0) {
            content
            tabBar
        }
        .background(MuseTheme.paper.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case 0:
            NavigationStack {
                AgentView()
            }
        case 1:
            NavigationStack {
                CanvasBoardView()
            }
        case 2:
            NavigationStack {
                SandboxView(shell: sandbox)
            }
        case 3:
            NavigationStack {
                SnippetListView()
            }
        case 4:
            NavigationStack {
                PromptLabView()
            }
        default:
            NavigationStack {
                SettingsView()
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = tab.id
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: selection == tab.id ? .semibold : .regular))
                            .scaleEffect(selection == tab.id ? 1.06 : 1)
                        Text(tab.title)
                            .font(MuseFont.mono(9, .medium))
                            .tracking(0.4)
                    }
                    .foregroundColor(selection == tab.id ? MuseTheme.rust : MuseTheme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.top, 4)
        .background {
            MuseTheme.surface
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MuseTheme.hairline)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(MuseStore())
    }
}
