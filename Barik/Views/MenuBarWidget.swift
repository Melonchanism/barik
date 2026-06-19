//
//  MenuBarWidget.swift
//  Barik
//
//  Created by josh on 6/19/26.
//
import SwiftUI

struct MenuBarWidget<Content: View>: View {
	var id: String
	var content: Content
	var popup: any View
	
	@State var rect: CGRect = .zero
	
	init(id: String, popup: () -> any View, content: @escaping () -> Content) {
		self.content = content()
		self.popup = popup()
		self.id = id
	}
	
	var body: some View {
		self.content
			.shadow(color: .foregroundShadowOutside, radius: 3)
			.background(Color.black.opacity(0.001))
			.contentShape(Rectangle())
			.background(
				GeometryReader { geometry in
					Color.clear
						.onChange(of: geometry.frame(in: .global), initial: true) { _, newValue in
							rect = newValue
						}
				}
			)
			.onTapGesture {
				MenuBarPopup.show(rect: rect, id: self.id, content: { AnyView(self.popup) })
			}
	}
}
