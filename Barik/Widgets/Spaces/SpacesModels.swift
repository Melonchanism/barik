import AppKit

protocol SpaceModel: Identifiable, Equatable, Codable {
	associatedtype WindowType: WindowModel
	var id: String { get }
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
