//
//  AudioPopup.swift
//  Barik
//
//  Created by josh on 6/4/26.
//
import SwiftUI

struct AudioPopup: View {
	var configProvider: ConfigProvider

	@ObservedObject var audioManager = AudioManager.shared

	@State private var offset: CGFloat = 0
	@State private var dragging: Bool = false

	var body: some View {
		HStack {
			VStack {
				ZStack {
					RoundedRectangle(cornerRadius: .infinity)
						.fill(.gray)
						.frame(maxWidth: 4, maxHeight: 200)
					RoundedRectangle(cornerRadius: .infinity)
						.fill(.white)
						.frame(maxWidth: 30, maxHeight: 14)
						.offset(y: offset)
						.gesture(
							DragGesture()
								.onChanged {
									offset = $0.location.y
									audioManager.setVolume(Float32(-offset / 200 + 0.5))
									dragging = true
								}
								.onEnded { _ in
									withAnimation {
										offset = -CGFloat((audioManager.volume ?? 0) * 200 - 100)
										dragging = false
									}
								}
						)
						.onChange(of: audioManager.volume, initial: true) {
							withAnimation {
								guard dragging == false else { return }
								offset = -CGFloat((audioManager.volume ?? 0) * 200 - 100)
							}
						}
						.opacity(audioManager.outputDevice!.canSetVolume ? 1 : 0)
				}
				Text(
					audioManager.outputDevice!.canSetVolume
						? "\(Int((audioManager.volume ?? 0) * 100))%" : "N/A"
				)
				.contentTransition(.numericText(value: Double(audioManager.volume ?? 0)))
				.animation(.default, value: audioManager.volume)
			}
			Divider()
				.frame(maxHeight: 200)
			VStack {
				ForEach(audioManager.devices.filter { $0.hasOutput }) { device in
					HStack {
						Image(systemName: "speaker.wave.2.fill")
							.bold()
							.padding(6)
							.background(
								Circle().fill(
									device == audioManager.outputDevice ? Color.accentColor : .gray.opacity(0.5)))
						Text(device.name)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.onTapGesture {
						audioManager.setOutput(device: device)
					}
				}
			}
		}
		.scrollDisabled(true)
		.frame(width: 300)
		.padding(30)
	}
}
