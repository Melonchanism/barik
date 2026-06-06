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

	var body: some View {
		HStack {
			AudioFaderView()
			Divider()
				.frame(maxHeight: 200)
				.padding(2)
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
		.frame(width: 300)
		.padding(30)
	}
}

struct AudioFaderView: View {
	@ObservedObject var audioManager = AudioManager.shared

	@State private var offset: CGFloat = 100
	@State private var preOffset: CGFloat = 0
	@State private var dragging: Bool = false

	var body: some View {
		VStack {
			ZStack {
				RoundedRectangle(cornerRadius: .infinity)
					.fill(.gray.opacity(0.5))
					.frame(maxWidth: 5, maxHeight: 200)
				RoundedRectangle(cornerRadius: .infinity)
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
			
			Text(audioManager.volume != nil ? "\(Int((audioManager.volume!) * 100))%" : "N/A")
				.contentTransition(.numericText(value: Double(audioManager.volume ?? 0)))
				.animation(.default, value: audioManager.volume)
		}
	}
}
