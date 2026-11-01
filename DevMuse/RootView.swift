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
                Label("Agent", systemImage: "sparkles")
            }
            .tag(0)

            NavigationStack {
                CanvasBoardView()
            }
            .tabItem {
                Label("Board", systemImage: "square.grid.2x2")
            }
            .tag(1)

            NavigationStack {
                SnippetListView()
            }
            .tabItem {
                Label("Vault", systemImage: "curlybraces")
            }
            .tag(2)

            NavigationStack {
                PromptLabView()
            }
            .tabItem {
                Label("Prompts", systemImage: "text.quote")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Studio", systemImage: "slider.horizontal.3")
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
