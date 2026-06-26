//
//  MenuBarWidget.swift
//  Barik
//
//  Created by josh on 6/24/26.
//

import AXSwift
import SwiftUI

struct MenuBarWidget: View {
	@ObservedObject var manager = MenuBarManager.shared

	@State private var animatedWidth: CGFloat = 0

	var body: some View {
		if let root = manager.current,
			let name = NSRunningApplication(processIdentifier: manager.pid ?? 0)?.localizedName
		{
			Text(name)
				.bold()
				.overlay {
					MenuItemView(item: root, overriddenTitle: "")
						.menuStyle(.borderlessButton)
						.menuIndicator(.hidden)
				}
				.fixedSize()
				.background(
					GeometryReader { geo in
						Color.clear
							.onChange(of: name, initial: true) { _, _ in
								withAnimation(.default) { animatedWidth = geo.size.width }
							}
					}
				)
				.frame(width: animatedWidth, alignment: .leading)
		}
	}
}

struct MenuItemView: View {
	var item: MenuItem
	var overriddenTitle: String?

	var body: some View {
		if !item.isLeaf {
			Menu(overriddenTitle ?? item.title ?? "") {
				ForEach(item.children!, id: \.element.description) { child in
					MenuItemView(item: child)
				}
			}
		} else if item.title == "" {
			Divider()
		} else {
			Button(overriddenTitle ?? item.title ?? "") {
				try? item.element.performAction(.press)
			}
			.disabled(!item.enabled)
		}
	}
}
