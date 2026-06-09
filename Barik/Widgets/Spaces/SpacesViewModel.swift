import AppKit
import Combine
import Foundation
import notify

class SpacesViewModel: ObservableObject {
	@Published var spaces: [AnySpace] = []
	private var timer: Timer?
	private var provider: AnySpacesProvider?
	
	var token: Int32 = 0

	init() {
		let runningApps = NSWorkspace.shared.runningApplications.compactMap {
			$0.localizedName?.lowercased()
		}
		if runningApps.contains("yabai") {
			provider = AnySpacesProvider(YabaiSpacesProvider())
		} else if runningApps.contains("aerospace") {
			provider = AnySpacesProvider(AerospaceSpacesProvider())
		} else {
			provider = nil
		}
		startMonitoring()
	}

	deinit {
		stopMonitoring()
	}

	private func startMonitoring() {
		if let yabai = self.provider?.provider as? YabaiSpacesProvider {
			yabai.registerListeners()
			notify_register_dispatch("WMUpdate", &token, DispatchQueue.main) { _ in self.loadSpaces() }
		} else {
			timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
				self.loadSpaces()
			}
		}
		loadSpaces()
	}

	private func stopMonitoring() {
		timer?.invalidate()
		timer = nil
	}

	private func loadSpaces() {
		DispatchQueue.global(qos: .background).async {
			guard let provider = self.provider,
				let spaces = provider.getSpacesWithWindows()
			else {
				DispatchQueue.main.async {
					self.spaces = []
				}
				return
			}
			let sortedSpaces = spaces.sorted { $0.id < $1.id }
			DispatchQueue.main.async {
				self.spaces = sortedSpaces
			}
		}
	}

	func switchToSpace(_ space: AnySpace, needWindowFocus: Bool = false) {
		DispatchQueue.global(qos: .userInitiated).async {
			self.provider?.focusSpace(
				spaceId: space.id,
				needWindowFocus: needWindowFocus
			)
		}
	}

	func switchToWindow(_ window: AnyWindow) {
		DispatchQueue.global(qos: .userInitiated).async {
			self.provider?.focusWindow(windowId: String(window.id))
		}
	}
}

class IconCache {
	static let shared = IconCache()
	private let cache = NSCache<NSString, NSImage>()
	private init() {}
	func icon(for appName: String) -> NSImage? {
		if let cached = cache.object(forKey: appName as NSString) {
			return cached
		}
		let workspace = NSWorkspace.shared
		if let app = workspace.runningApplications.first(where: {
			$0.localizedName == appName
		}),
			let bundleURL = app.bundleURL
		{
			let icon = workspace.icon(forFile: bundleURL.path)
			cache.setObject(icon, forKey: appName as NSString)
			return icon
		}
		return nil
	}
}
