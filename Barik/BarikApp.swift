import SwiftUI

@main
struct BarikApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
                .onChange(of: ConfigManager.shared.config.dockIcon) { oldValue, value in
                    if value == true { NSApp.setActivationPolicy(.regular) }
                    else { NSApp.setActivationPolicy(.accessory) }
                }
        }
    }
}
