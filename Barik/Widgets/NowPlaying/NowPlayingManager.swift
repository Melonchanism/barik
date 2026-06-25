import AppKit
import Combine
import Foundation
import ScriptingBridge

// MARK: - Playback State

/// Represents the current playback state.
enum PlaybackState: AEKeyword {
	case stopped = 0x6b50_5353 /* b'kPSS' */
	case playing = 0x6b50_5350 /* b'kPSP' */
	case paused = 0x6b50_5370 /* b'kPSp' */
	case fastForwarding = 0x6b50_5346 /* b'kPSF' */
	case rewinding = 0x6b50_5352 /* b'kPSR' */

	static func standard(value: AEKeyword?) -> Self? {
		guard let value = value else { return nil }
		return Self(rawValue: value)
	}
}

// MARK: - Now Playing Song Model

/// A model representing the currently playing song.
struct NowPlayingSong: Equatable, Identifiable {
	var id: String { (title ?? "NULL") + (artist ?? "NULL") }
	var appName: String
	var title: String?
	var artist: String?
	var albumArt: NSImage?
	var duration: Double?  // Duration in seconds

	/// Initializes a song model from individual fields.
	init(
		appName: String,
		title: String?,
		artist: String?,
		albumArt: NSImage?,
		duration: Double?
	) {
		self.appName = appName
		self.title = title
		self.artist = artist
		self.albumArt = albumArt
		self.duration = duration
	}

	static func == (lhs: NowPlayingSong, rhs: NowPlayingSong) -> Bool {
		return lhs.id == rhs.id
	}
}

// MARK: - Now Playing Manager

/// An observable manager that periodically updates the now playing song.
class NowPlayingManager: ObservableObject {
	static var shared = NowPlayingManager()

	private var providers: [NowPlayingProvider] {
		var providers: [NowPlayingProvider?] = [MusicProvider(), SpotifyProvider()]
		return providers.filter { $0 != nil } as! [NowPlayingProvider]
	}
	private var activeProvider: NowPlayingProvider? { providers.first { $0.state != .stopped } }

	private var cancellables: Set<AnyCancellable>

	@Published private(set) var nowPlaying: NowPlayingSong?
	@Published var position: TimeInterval
	@Published var state: PlaybackState

	private init() {
		self.position = 0
		self.state = .stopped
		self.cancellables = .init()
		self.updateNowPlaying()
		Publishers.MergeMany(
			providers.map { DistributedNotificationCenter.default().publisher(for: $0.notificationName) }
		)
		.sink { _ in self.updateNowPlaying() }
		.store(in: &cancellables)

		Timer.publish(every: 1, on: .main, in: .common)
			.autoconnect()
			.sink { timer in
				if self.activeProvider?.state == .playing { self.position += 1 }
			}
			.store(in: &cancellables)
	}

	/// Updates the now playing song asynchronously.
	private func updateNowPlaying() {
		DispatchQueue.main.async { [self] in
			state = activeProvider?.state ?? .stopped
			guard state != .stopped else { return }
			if nowPlaying != activeProvider?.nowPlaying { nowPlaying = activeProvider?.nowPlaying }
			position = activeProvider?.position ?? 0
		}
	}

	func togglePlayPause() { activeProvider?.playPause() }
	func previousTrack() { activeProvider?.prevTrack() }
	func nextTrack() { activeProvider?.nextTrack() }
	func seek(to time: TimeInterval) { activeProvider?.seek(to: time) }

	func focusApp() {
		guard let name = activeProvider?.name else { return }
		NSAppleScript(source: "tell application \"\(name)\" to reopen")?.executeAndReturnError(nil)
		NSAppleScript(source: "tell application \"\(name)\" to activate")?.executeAndReturnError(nil)
	}
}
