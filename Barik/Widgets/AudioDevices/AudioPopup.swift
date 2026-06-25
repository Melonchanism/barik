import Combine
//
//  AudioPopup.swift
//  Barik
//
//  Created by josh on 6/4/26.
//
import SwiftUI

struct AudioPopup: View {
	var configProvider: ConfigProvider

	@ObservedObject private var audioManager = AudioManager.shared

	var body: some View {
		HStack(spacing: 4) {
			AudioFaderView()
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
									device == audioManager.outputDevice ? Color.accentColor : .gray.opacity(0.5))
							)
						Text(device.name)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.onTapGesture {
						audioManager.setOutput(device: device)
					}
				}
			}
		}
		.frame(width: 300)
		.padding(30)
	}
}

struct AudioFaderView: View {
	@ObservedObject var audioManager = AudioManager.shared

	@State private var offset: CGFloat = 100
	@State private var preOffset: CGFloat = 0
	@State private var dragging: Bool = false

	private var displayedVolume: Int {
		dragging ? Int((-offset / 200 + 0.5) * 100) : Int((audioManager.volume ?? 0) * 100)
	}

	var body: some View {
		VStack(spacing: 12) {
			ZStack {
				Capsule()
					.fill(.gray.opacity(0.5))
					.frame(maxWidth: 5, maxHeight: 200)
				Capsule()
					.fill(.white)
					.frame(maxWidth: 30, maxHeight: 14)
					.offset(y: offset)
					.opacity(audioManager.volume != nil ? 1 : 0)
			}
			.background(Color.black)
			.gesture(
				DragGesture(minimumDistance: .zero)
					.onChanged {
						if !dragging {
							preOffset = offset
							dragging = true
						}
						offset = $0.translation.height + preOffset
						audioManager.setVolume(Float32(-offset / 200 + 0.5))
					}
					.onEnded { _ in
						dragging = false
						withAnimation {
							offset = -CGFloat((audioManager.volume ?? 0) * 200 - 100)
						}
					}
			)
			.onChange(of: audioManager.volume, initial: true) {
				withAnimation {
					guard dragging == false else { return }
					offset = -CGFloat((audioManager.volume ?? 0) * 200 - 100)
				}
			}

			Text(audioManager.outputDevice?.canSetVolume == true ? "\(displayedVolume)%" : "N/A")
				.monospaced()
				.contentTransition(.numericText(value: Double(displayedVolume)))
				.animation(.snappy(duration: 0.05), value: displayedVolume)
		}
		.frame(minWidth: 50)
	}
}
