//
//  AudioWidget.swift
//  Barik
//
//  Created by josh on 6/4/26.
//
import SwiftUI

struct AudioWidget: View {
	@EnvironmentObject var configProvider: ConfigProvider

	@ObservedObject var audioManager = AudioManager.shared

	@State private var widgetFrame: CGRect = .zero

	var body: some View {
		VStack {
			Image(systemName: "speaker.wave.3.fill", variableValue: (audioManager.outputDevice?.canSetVolume ?? false) ? Double(audioManager.volume ?? 1) : 1)
				.bold()
				.monospaced()
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
