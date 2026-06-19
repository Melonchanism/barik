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
		MenuBarWidget(id: "applemenu", popup: { AppleMenuPopup() }) {
			Image(systemName: "apple.logo")
				.imageScale(.large)
		}
	}
}
