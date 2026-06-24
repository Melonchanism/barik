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
		BarWidget(
			id: "audiodevices",
			popup: {
				AudioPopup(configProvider: configProvider)
			}
		) {
			Image(
				systemName: audioManager.volume == 0 ? "speaker.slash.fill" : "speaker.wave.3.fill",
				variableValue: Double(audioManager.volume ?? 1)
			)
			.bold()
			.monospaced()
		}
	}
}
