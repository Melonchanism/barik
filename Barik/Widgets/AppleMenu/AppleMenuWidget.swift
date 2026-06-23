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

private func openApp(_ path: String) {
	NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init())
}
