import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: MuseStore
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                AgentView()
            }
            .tabItem {
                Label("助手", systemImage: "sparkles")
            }
            .tag(0)

            NavigationStack {
                CanvasBoardView()
            }
            .tabItem {
                Label("画布", systemImage: "square.grid.2x2")
            }
            .tag(1)

            NavigationStack {
                SnippetListView()
            }
            .tabItem {
                Label("代码库", systemImage: "curlybraces")
            }
            .tag(2)

            NavigationStack {
                PromptLabView()
            }
            .tabItem {
                Label("提示词", systemImage: "text.quote")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "slider.horizontal.3")
            }
            .tag(4)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(MuseStore())
    }
}
