//
//  MenuBarManager.swift
//  Barik
//
//  Created by josh on 6/23/26.
//
import AXSwift
import AppKit
import Combine

class MenuBarManager: ObservableObject {
	static let shared = MenuBarManager()
	
	let axQueue = DispatchQueue(label: "ax", qos: .userInteractive)

	var applications: [pid_t: MenuItem] = [:]
	@Published var current: MenuItem?
	@Published var pid: pid_t?

	init() {
		EventManager.shared.addListener(for: .frontSwitched) { [self] type, psn, pid in
			guard NSRunningApplication(processIdentifier: pid)?.localizedName != "Barik" else { return }
			setCurrent(pid: pid)
		}

		EventManager.shared.addListener(for: .terminated) { [self] type, psn, pid in
			applications.removeValue(forKey: pid)
		}

		// Front app will auto be selected since Barik focuses itself
	}

	func setCurrent(pid: pid_t, retryCount: Int = 0) {
		axQueue.async { [self] in
			if applications[pid] == nil {
				guard
					let app = Application(forProcessID: pid),
					let menuBar = try? app.attribute(.menuBar) as UIElement?
				else {
					if retryCount >= 3 { return }
					axQueue.asyncAfter(deadline: .now() + 0.5) {
						self.setCurrent(pid: pid, retryCount: retryCount + 1)
					}
					return
				}
					let rootItem = MenuItem.create(from: menuBar)
				DispatchQueue.main.async {
					self.applications[pid] = rootItem
				}
			}

//			let obs = try? Observer(processID: pid) { observer, element, notification in }
//			try? obs?.addNotification(.mainWindowChanged, forElement: Application(forProcessID: pid)!)
			
			DispatchQueue.main.async {
				self.pid = pid
				self.current = self.applications[pid]!
			}
		}
	}
}

class MenuBarApplication: ObservableObject {
	var pid: pid_t
	var rootMenu: MenuItem
	var app: Application
	var menuBar: UIElement

	init(pid: pid_t, rootMenu: MenuItem, app: Application, menuBar: UIElement) {
		self.pid = pid
		self.rootMenu = rootMenu
		self.app = app
		self.menuBar = menuBar
	}
}

class MenuItem: CustomDebugStringConvertible {
	let element: UIElement
	let role: String
	let title: String?
	let enabled: Bool
	var children: [MenuItem]?

	init(
		element: UIElement, role: String, title: String?,
		enabled: Bool, children: [MenuItem]? = nil
	) {
		self.element = element
		self.role = role
		self.title = title
		self.enabled = enabled
		self.children = children
	}

	var isLeaf: Bool { children?.isEmpty ?? true }
	var isActionable: Bool { enabled == true && isLeaf }

	func click() {
		guard isActionable else { return }
		try? element.performAction(.press)
	}

	static func create(from element: UIElement, fallbackTitle: String? = nil) -> MenuItem? {
		guard
			let role = try? element.attribute(.role) as String?
		else { return nil }

		let title = try? element.attribute(.title) as String? ?? fallbackTitle
		let enabled = try? element.attribute(.enabled) as Bool?

		let axChildren: [AXUIElement] = (try? element.attribute(.children) as [AXUIElement]?) ?? []

		let children: [MenuItem] = axChildren.compactMap {
			MenuItem.create(from: UIElement($0), fallbackTitle: title)
		}

		// If this node is just a container with a single menu child, unwrap it
		if children.count == 1, children[0].role == kAXMenuRole {
			return children[0]
		}

		return MenuItem(
			element: element,
			role: role,
			title: title,
			enabled: enabled ?? false,
			children: children.isEmpty ? nil : children
		)
	}

	var debugDescription: String {
		let childCount = children?.count ?? 0
		return "\(title ?? "Untitled"): \(role) \(childCount > 0 ? "(\(childCount) children)" : "")"
	}
}
