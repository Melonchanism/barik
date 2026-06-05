import Combine
import Foundation
import IOKit.ps
import SwiftUI

/// This class monitors the battery status.
class BatteryManager: ObservableObject {
	static var shared = BatteryManager()

	@Published var batteryLevel: Int = 0
	@Published var isCharging: Bool = false
	@Published var isPluggedIn: Bool = false
	@Published var isLowPower: Bool = false

	private var source: CFRunLoopSource?
	private var cancellable: AnyCancellable?

	init() {
		source = IOPSNotificationCreateRunLoopSource(
			updateBatteryStatus,
			Unmanaged.passUnretained(self).toOpaque()
		).takeRetainedValue()

		CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
		updateBatteryStatus(Unmanaged.passUnretained(self).toOpaque())

		cancellable = NotificationCenter.default.publisher(
			for: Notification.Name.NSProcessInfoPowerStateDidChange
		).sink { _ in
			DispatchQueue.main.async {
				self.isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
			}
		}
		self.isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
	}

	deinit {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
	}

	var color: Color {
		if self.isCharging {
			return .green
		} else {
			if self.isLowPower {
				return .yellow
			} else if self.batteryLevel < 20 {
				return .red
			} else {
				return .white
			}
		}
	}
}

/// This method updates the battery level and charging state.
private func updateBatteryStatus(_ context: UnsafeMutableRawPointer?) {
	let manager = Unmanaged<BatteryManager>.fromOpaque(context!).takeUnretainedValue()

	guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
		let sources = IOPSCopyPowerSourcesList(snapshot)?
			.takeRetainedValue() as? [CFTypeRef]
	else {
		return
	}

	for source in sources {
		if let description = IOPSGetPowerSourceDescription(
			snapshot,
			source
		)?.takeUnretainedValue() as? [String: Any],
			let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
			let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int,
			let charging = description[kIOPSIsChargingKey as String] as? Bool,
			let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String
		{
			let isAC = (powerSourceState == kIOPSACPowerValue)
			
			DispatchQueue.asyncIfNeeded {
				manager.batteryLevel = (currentCapacity * 100) / maxCapacity
				manager.isCharging = charging
				manager.isPluggedIn = isAC
			}
		}
	}
}

extension DispatchQueue {
	static func asyncIfNeeded(_ block: @escaping () -> Void) {
		if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
	}
}
