//
//  EventManager.swift
//  Barik
//
//  Created by josh on 6/24/26.
//
import ApplicationServices
import Carbon
import Combine

class EventManager: ObservableObject {
	static let shared = EventManager()

	var handler: EventHandlerRef?
	var types = [
		EventTypeSpec(
			eventClass: OSType(kEventClassApplication), eventKind: UInt32(kEventAppLaunched)),
		EventTypeSpec(
			eventClass: OSType(kEventClassApplication), eventKind: UInt32(kEventAppTerminated)),
		EventTypeSpec(
			eventClass: OSType(kEventClassApplication), eventKind: UInt32(kEventAppFrontSwitched)),
	]

	var listeners: [UInt64: Listener] = [:]

	init() {
		InstallEventHandler(
			GetApplicationEventTarget(), handleEvent,
			types.count, types,
			Unmanaged.passUnretained(self).toOpaque(), &handler
		)
	}

	func addListener(for type: EventType, callback: @escaping Listener.Callback) -> UInt64 {
		var rng = SystemRandomNumberGenerator()
		var id = rng.next(upperBound: UInt64(32))
		listeners[id] = Listener(id: id, type: type, callback: callback)
		return id
	}

	func removeListener(id: UInt64) {
		listeners.removeValue(forKey: id)
	}
}

struct EventType: OptionSet {
	let rawValue: Int

	static let launched = EventType(rawValue: 1 << 0)
	static let frontSwitched = EventType(rawValue: 1 << 1)
	static let terminated = EventType(rawValue: 1 << 2)
}

struct Listener {
	typealias Callback = (EventType, ProcessSerialNumber, pid_t) -> Void
	var id: UInt64
	var type: EventType
	var callback: Callback
}

private func handleEvent(
	ref: EventHandlerCallRef?, event: EventRef?, context: UnsafeMutableRawPointer?
) -> OSStatus {
	let eventHandler = Unmanaged<EventManager>.fromOpaque(context!).takeUnretainedValue()

	var psn = ProcessSerialNumber()
	var pid = pid_t()

	guard
		GetEventParameter(
			event, EventParamName(kEventParamProcessID), typeProcessSerialNumber,
			nil, MemoryLayout<ProcessSerialNumber>.stride, nil, &psn
		) == noErr,
		og_GetProcessPID(&psn, &pid) == noErr
	else { return -1 }

	let type: EventType = {
		switch GetEventKind(event) {
		case UInt32(kEventAppLaunched):
			EventType.launched
		case UInt32(kEventAppFrontSwitched):
			EventType.frontSwitched
		case UInt32(kEventAppTerminated):
			EventType.terminated
		default:
			[]
		}
	}()

	for listener in eventHandler.listeners.values {
		if listener.type.contains(type) {
			listener.callback(type, psn, pid)
		}
	}

	return noErr
}
