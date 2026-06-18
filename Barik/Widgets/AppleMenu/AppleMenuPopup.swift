//
//  AppleMenuPopup.swift
//  Barik
//
//  Created by josh on 6/11/26.
//
import SwiftUI

struct AppleMenuPopup: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Button("Lock Screen", systemImage: "lock.fill") {
				SACLockScreenImmediate()
			}
			Button("Screen Saver", systemImage: "photo.fill") {
				SACScreenSaverStartNow(0, 0, 0)
			}
			Button("Login Window", systemImage: "person.circle.fill") {
				SACSwitchToLoginWindow()
			}
			Button("Log Out", systemImage: "rectangle.portrait.and.arrow.right.fill") {
				SACLOStartLogout(0, 0, 0, 0)
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
		}
		.buttonStyle(.plain)
		.frame(maxWidth: 200)
		.padding(30)
	}

	private func openApp(_ path: String) {
		NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init())
	}
}
