import Foundation
import notify

class YabaiSpacesProvider: SpacesProvider, SwitchableSpacesProvider {
	typealias SpaceType = YabaiSpace

	@discardableResult
	private func runYabaiCommand(arguments: [String]) -> Data? {
		var arguments = arguments
		if arguments.first == "-m" { arguments.removeFirst() }
		
		let fd = socket(AF_UNIX, SOCK_STREAM, 0)
		guard fd >= 0 else {
			perror("socket")
			return nil
		}

		var addr = sockaddr_un()
		let socketPath = "/tmp/yabai_\(ProcessInfo.processInfo.userName).socket"

		addr.sun_family = sa_family_t(AF_UNIX)

		socketPath.utf8CString.withUnsafeBufferPointer { buf in
			let maxLen = MemoryLayout.size(ofValue: addr.sun_path)
			let copyLen = min(buf.count, maxLen)
			withUnsafeMutablePointer(to: &addr.sun_path) { destPtr in
				destPtr.withMemoryRebound(to: CChar.self, capacity: maxLen) { dest in
					memcpy(dest, buf.baseAddress!, copyLen)
				}
			}
		}

		// compute actual sockaddr length: offsetof + path length (exclude trailing unused bytes)
		let pathLen = socketPath.utf8CString.count  // includes trailing NUL
		let sockAddrLen = socklen_t(MemoryLayout.offset(of: \sockaddr_un.sun_path)! + pathLen)

		let connectResult = withUnsafePointer(to: &addr) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
				connect(fd, ptr, sockAddrLen)
			}
		}
		guard connectResult == 0 else {
			perror("connect")
			close(fd)
			return nil
		}

		// build message matching original C: int (argc) + NUL-separated args + final NUL
		var messageLength = Int32(arguments.count)  // original used argc
		let argDatas = arguments.map { $0.data(using: .utf8)! }
		for d in argDatas { messageLength += Int32(d.count) }

		var payload = Data()
		// Final NUL terminator
		var ml = Int32(messageLength + 1)
		withUnsafeBytes(of: &ml) { payload.append(contentsOf: $0) }
		for d in argDatas {
			payload.append(d)
			payload.append(0)
		}
		payload.append(0)

		let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)

		do {
			try handle.write(contentsOf: payload)
		} catch {
			print("write error:", error)
			try? handle.close()
			return nil
		}

		shutdown(fd, SHUT_WR)

		return handle.readDataToEndOfFile()
	}

	private func fetchSpaces() -> [YabaiSpace]? {
		guard
			let data = runYabaiCommand(arguments: ["-m", "query", "--spaces"])
		else {
			return nil
		}
		let decoder = JSONDecoder()
		do {
			let spaces = try decoder.decode([YabaiSpace].self, from: data)
			return spaces
		} catch {
			print("Decode yabai spaces error: \(error)")
			return nil
		}
	}

	private func fetchWindows() -> [YabaiWindow]? {
		guard
			let data = runYabaiCommand(arguments: ["-m", "query", "--windows"])
		else {
			return nil
		}
		let decoder = JSONDecoder()
		do {
			let windows = try decoder.decode([YabaiWindow].self, from: data)
			return windows
		} catch {
			print("Decode yabai windows error: \(error)")
			return nil
		}
	}

	func getSpacesWithWindows() -> [YabaiSpace]? {
		return getSpaces()?.filter { !$0.windows.isEmpty }
	}

	func getSpaces() -> [YabaiSpace]? {
		guard let spaces = fetchSpaces(), let windows = fetchWindows() else {
			return nil
		}
		let filteredWindows = windows.filter {
			!($0.isHidden || $0.isFloating || $0.isSticky)
		}
		var spaceDict = Dictionary(
			uniqueKeysWithValues: spaces.map { ($0.id, $0) }
		)
		for window in filteredWindows {
			if var space = spaceDict[window.spaceId] {
				space.windows.append(window)
				spaceDict[window.spaceId] = space
			}
		}
		var resultSpaces = Array(spaceDict.values)
		for i in 0..<resultSpaces.count {
			resultSpaces[i].windows.sort { $0.stackIndex < $1.stackIndex }
		}
		return resultSpaces
	}

	func focusSpace(spaceId: String, needWindowFocus: Bool) {
		runYabaiCommand(arguments: ["-m", "space", "--focus", spaceId])
		if !needWindowFocus { return }

		DispatchQueue.global(qos: .userInitiated).asyncAfter(
			deadline: .now() + 0.1
		) {
			if let spaces = self.getSpacesWithWindows() {
				if let space = spaces.first(where: { $0.id == Int(spaceId) }) {
					let hasFocused = space.windows.contains { $0.isFocused }
					if !hasFocused, let firstWindow = space.windows.first {
						self.runYabaiCommand(arguments: [
							"-m", "window", "--focus", String(firstWindow.id),
						])
					}
				}
			}
		}
	}

	func focusWindow(windowId: String) {
		runYabaiCommand(arguments: ["-m", "window", "--focus", windowId])
	}

	func registerListeners() {
		if String(
			data: runYabaiCommand(arguments: ["-m", "signal", "--list"]) ?? Data(),
			encoding: .utf8
		)?
			.contains("Barik") ?? true
		{
			return
		}
		DispatchQueue.global(qos: .userInitiated).async {
			for event in [
				"window_focused", "window_minimized", "window_destroyed", "window_title_changed",
				"space_changed",
			] {
				self.runYabaiCommand(
					arguments: [
						"-m",
						"signal",
						"--add",
						"event=\(event)",
						"action=notifyutil -p WMUpdate",
						"label=\(event)Barik",
					]
				)
			}
		}
	}
}
