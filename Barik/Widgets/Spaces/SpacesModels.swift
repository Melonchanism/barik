import AppKit

protocol SpaceModel: Identifiable, Equatable, Codable {
	associatedtype WindowType: WindowModel
	var isFocused: Bool { get set }
	var windows: [WindowType] { get set }
}

protocol WindowModel: Identifiable, Equatable, Codable {
	var id: Int { get }
	var title: String { get }
	var appName: String? { get }
	var isFocused: Bool { get }
	var appIcon: NSImage? { get set }
}

protocol SpacesProvider {
	associatedtype SpaceType: SpaceModel
	func getSpacesWithWindows() -> [SpaceType]?
	func getSpaces() -> [SpaceType]?
}

protocol SwitchableSpacesProvider: SpacesProvider {
	func focusSpace(spaceId: String, needWindowFocus: Bool)
	func focusWindow(windowId: String)
}

struct AnyWindow: Identifiable, Equatable {
	let id: Int
	let title: String
	let appName: String?
	let isFocused: Bool
	let appIcon: NSImage?

	init<W: WindowModel>(_ window: W) {
		self.id = window.id
		self.title = window.title
		self.appName = window.appName
		self.isFocused = window.isFocused
		self.appIcon = window.appIcon
	}

	static func == (lhs: AnyWindow, rhs: AnyWindow) -> Bool {
		return lhs.id == rhs.id && lhs.title == rhs.title
			&& lhs.appName == rhs.appName && lhs.isFocused == rhs.isFocused
	}
}

struct AnySpace: Identifiable, Equatable {
	let id: String
	let isFocused: Bool
	let windows: [AnyWindow]

	init<S: SpaceModel>(_ space: S) {
		if let aero = space as? AeroSpace {
			self.id = aero.workspace
		} else if let yabai = space as? YabaiSpace {
			self.id = String(yabai.id)
		} else {
			self.id = "0"
		}
		self.isFocused = space.isFocused
		self.windows = space.windows.map { AnyWindow($0) }
	}

	static func == (lhs: AnySpace, rhs: AnySpace) -> Bool {
		return lhs.id == rhs.id && lhs.isFocused == rhs.isFocused
			&& lhs.windows == rhs.windows
	}
}

func AnySpacesProvider(_ provider: any SwitchableSpacesProvider) -> any SwitchableSpacesProvider {
	return provider as any SwitchableSpacesProvider
}
