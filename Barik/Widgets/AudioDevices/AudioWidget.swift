//
//  AudioWidget.swift
//  Barik
//
//  Created by josh on 6/4/26.
//
import SwiftUI

struct AudioWidget: View {
	@EnvironmentObject var configProvider: ConfigProvider

	@StateObject var audioManager = AudioManager()

	@State private var widgetFrame: CGRect = .zero

	var body: some View {
		HStack {
			Text("\(audioManager.outputDeviceName ?? "")")
			Text("\(Int((audioManager.volume ?? 1) * 100))%")
				.monospaced()
				.contentTransition(.numericText(value: Double(audioManager.volume ?? 1)))
				.animation(.default, value: audioManager.volume)
		}
		.background(
			GeometryReader { geometry in
				Color.clear
					.onAppear {
						widgetFrame = geometry.frame(in: .global)
					}
					.onChange(of: geometry.frame(in: .global)) { _, newFrame in
						widgetFrame = newFrame
					}
			}
		)
		.onTapGesture {
			MenuBarPopup.show(rect: widgetFrame, id: "audiodevices") {
				AudioPopup(configProvider: configProvider)
			}
		}
	}
}
