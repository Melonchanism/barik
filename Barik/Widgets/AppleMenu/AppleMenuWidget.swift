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
		Image(systemName: "apple.logo")
			.background(
				GeometryReader { geometry in
					Color.clear
						.onChange(of: geometry.frame(in: .global), initial: true) {
							rect = $1
						}
				}
			)
			.imageScale(.large)
			.shadow(radius: 2)
			.onTapGesture {
				MenuBarPopup.show(rect: rect, id: "applemenu", content: { AppleMenuPopup() })
			}
	}
}
