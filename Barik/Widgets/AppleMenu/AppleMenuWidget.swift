//
//  AppleMenuWidget.swift
//  Barik
//
//  Created by josh on 6/11/26.
//
import SwiftUI

struct AppleMenuWidget: View {
	@State private var rect: CGRect = CGRect()

	var body: some View {
		Menu {
			Button("Lock Screen", systemImage: "lock.fill") {
				_ = Login.shared.SACLockScreenImmediate()
			}
			Button("Screen Saver", systemImage: "photo.fill") {
				_ = Login.shared.SACScreenSaverStartNow(0, 0, 0)
			}
			Button("Login Window", systemImage: "person.circle.fill") {
				_ = Login.shared.SACSwitchToLoginWindow()
			}
			Button("Log Out", systemImage: "rectangle.portrait.and.arrow.right.fill") {
				_ = Login.shared.SACLOStartLogout(0, 0, 0, 0)
			}

			Divider()

			Button("System Settings", systemImage: "gear") {
				openApp("/System/Applications/System Settings.app")
			}
			Button("About This Mac", systemImage: "info") {
				NSWorkspace.shared.open(
					URL(string: "x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension")!
				)
			}
			Button("System Information", systemImage: "cpu.fill") {
				openApp("/System/Applications/Utilities/System Information.app")
			}
		} label: {
			Image(systemName: "apple.logo")
		}
		.menuStyle(.borderlessButton)
		.menuIndicator(.hidden)
		.scaleEffect(1.25)
		.fixedSize()
		.background(Color.black.opacity(0.001))
	}
}

class Login {
	static let shared = Login()

	typealias F_SACLockScreenImmediate = @convention(c) () -> Int32
	typealias F_SACScreenSaverStartNow = @convention(c) (Int32, Int32, Int32) -> Int32
	typealias F_SACLOStartLogout = @convention(c) (Int32, Int32, Int32, Int32) -> Int32
	typealias F_SACSwitchToLoginWindow = @convention(c) () -> Int32

	let SACLockScreenImmediate: F_SACLockScreenImmediate
	let SACScreenSaverStartNow: F_SACScreenSaverStartNow
	let SACLOStartLogout: F_SACLOStartLogout
	let SACSwitchToLoginWindow: F_SACSwitchToLoginWindow

	init() {
		let handle = dlopen(
			"/System/Library/PrivateFrameworks/login.framework/Versions/A/login", RTLD_NOW
		)
		SACLockScreenImmediate = unsafeBitCast(
			dlsym(handle, "SACLockScreenImmediate"),
			to: F_SACLockScreenImmediate.self
		)
		SACScreenSaverStartNow = unsafeBitCast(
			dlsym(handle, "SACScreenSaverStartNow"),
			to: F_SACScreenSaverStartNow.self
		)
		SACLOStartLogout = unsafeBitCast(
			dlsym(handle, "SACLOStartLogout"),
			to: F_SACLOStartLogout.self
		)
		SACSwitchToLoginWindow = unsafeBitCast(
			dlsym(handle, "SACSwitchToLoginWindow"),
			to: F_SACSwitchToLoginWindow.self
		)
	}
}

private func openApp(_ path: String) {
	NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init())
}
