import SwiftUI
import UIKit

@main
struct DevMuseApp: App {
    @StateObject private var store = MuseStore()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(MuseTheme.paperDeep)
        appearance.shadowColor = UIColor(MuseTheme.hairline)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(MuseTheme.inkFaint)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(MuseTheme.inkFaint)]
        itemAppearance.selected.iconColor = UIColor(MuseTheme.rust)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(MuseTheme.rust)]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(MuseTheme.rust)
                .preferredColorScheme(store.appearance.colorScheme)
        }
    }
}
