import SwiftUI

// MARK: - Now Playing Widget

// PreferenceKey to send measured width up the view tree

struct NowPlayingWidget: View {
	@EnvironmentObject var configProvider: ConfigProvider
	@ObservedObject var playingManager = NowPlayingManager.shared

	@State private var widgetFrame: CGRect = .zero
	@State private var animatedWidth: CGFloat = 0

	@ObservedObject var configManager = ConfigManager.shared

	var foregroundHeight: CGFloat {
		configManager.config.experimental.foreground.resolveHeight()
	}

	var body: some View {
		BarWidget(id: "nowplaying", popup: { NowPlayingPopup(configProvider: configProvider) }) {
			if let song = playingManager.nowPlaying, playingManager.state != .stopped {
				HStack(spacing: 8) {
					AlbumArtView(song: song)
					SongTextView(song: song)
				}
				.fixedSize()
				.background(
					GeometryReader { geo in
						Color.clear
							.onChange(of: geo.size.width, initial: true) { _, newWidth in
								withAnimation(.default) { animatedWidth = newWidth }
							}
					}
				)
				.frame(width: animatedWidth, height: foregroundHeight < 45 ? 30 : 38, alignment: .leading)
				.padding(.horizontal, foregroundHeight < 45 ? 8 : 12)
				.background(configManager.config.experimental.foreground.widgetsBackground.blur)
				.clipShape(Capsule())
				.overlay(
					Capsule().stroke(Color.noActive, lineWidth: 1)
				)
			}
		}
	}
}

// MARK: - Album Art View

/// A view that displays the album art with a fade animation and a pause indicator if needed.
struct AlbumArtView: View {
	@ObservedObject var playingManager = NowPlayingManager.shared
	let song: NowPlayingSong

	var body: some View {
		ZStack {
			Image(nsImage: song.albumArt ?? NSImage())
				.resizable()
				.frame(width: 20, height: 20)
				.clipShape(RoundedRectangle(cornerRadius: 4))
				.brightness(playingManager.state == .paused ? -0.3 : 0)

			if playingManager.state == .paused {
				Image(systemName: "pause.fill")
					.foregroundColor(.icon)
					.transition(.blurReplace)
			}
		}
		.animation(.default, value: playingManager.state == .paused)
	}
}

// MARK: - Song Text View

/// A view that displays the song title and artist.
struct SongTextView: View {
	let song: NowPlayingSong
	@ObservedObject var configManager = ConfigManager.shared
	var foregroundHeight: CGFloat {
		configManager.config.experimental.foreground.resolveHeight()
	}

	var body: some View {

		VStack(alignment: .leading, spacing: -1) {
			if foregroundHeight >= 30 {
				Text(song.title ?? "Not Playing")
					.font(.system(size: 11))
					.fontWeight(.medium)
					.padding(.trailing, 2)
				Text(song.artist ?? "")
					.opacity(0.8)
					.font(.system(size: 10))
					.padding(.trailing, 2)
			} else {
				Text((song.artist ?? "Not Playing") + " — " + (song.title ?? ""))
					.font(.system(size: 12))
			}
		}
	}
}

// MARK: - Preview

struct NowPlayingWidget_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			NowPlayingWidget()
		}
		.frame(width: 500, height: 100)
	}
}
