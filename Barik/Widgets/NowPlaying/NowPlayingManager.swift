import AppKit
import Combine
import Foundation
import ScriptingBridge

// MARK: - Playback State

/// Represents the current playback state.
enum PlaybackState: String {
	case playing, paused, stopped
}

// MARK: - Now Playing Song Model

/// A model representing the currently playing song.
struct NowPlayingSong: Equatable, Identifiable {
	var id: String { title + artist }
	var appName: String
	var state: PlaybackState
	var title: String
	var artist: String
	var albumArt: NSImage?
	var position: Double?
	var duration: Double?  // Duration in seconds
	
	init() {
		appName = ""
		state = .stopped
		title = ""
		artist = ""
		albumArt = nil
		position = 0
		duration = 1
	}

	/// Initializes a song model from individual fields.
	init(
		appName: String,
		state: PlaybackState,
		title: String,
		artist: String,
		albumArt: NSImage?,
		position: Double?,
		duration: Double?
	) {
		self.appName = appName
		self.state = state
		self.title = title
		self.artist = artist
		self.albumArt = albumArt
		self.position = position
		self.duration = duration
	}
}

// MARK: - Supported Music Applications

/// Supported music applications with corresponding SBApplications.

struct MusicApp: CaseIterable, Equatable {
	var name: String
	var sbApp: any SBMusicApplicationProtocol
	
	static var spotifySBApp = SBApplication(bundleIdentifier: "com.spotify.client")! as SpotifyApplication
	static var musicSBApp = SBApplication(bundleIdentifier: "com.apple.Music")! as MusicApplication
	
	static var spotify = MusicApp(name: "Spotify", sbApp: spotifySBApp)
	static var music = MusicApp(name: "Music", sbApp: musicSBApp)
	
	static var allCases: [Self] = [spotify, music]
	
	static func == (lhs: MusicApp, rhs: MusicApp) -> Bool {
		lhs.name == rhs.name
	}
}

// MARK: - Now Playing Provider

/// Provides functionality to fetch the now playing song and execute playback commands.
final class NowPlayingProvider {

	/// Returns the current playing song from any supported music application.
	static func fetchNowPlaying(_ song: inout NowPlayingSong?) {
		if (song == nil) { song = NowPlayingSong() }
		for app in MusicApp.allCases {
			fetchNowPlaying(from: app, song: &song!)
		}
	}

	/// Returns the now playing song for a specific music application.
	private static func fetchNowPlaying(from app: MusicApp, song: inout NowPlayingSong) {
		if app == MusicApp.spotify {
			let spotify = MusicApp.spotify.sbApp as! SpotifyApplication
			if spotify.isRunning {
				let track: SpotifyTrack = spotify.currentTrack!
				if !(song.id == track.name ?? "" + (track.artist ?? "")) {
					song.title = track.name ?? ""
					song.artist = track.artist ?? ""
					song.albumArt = track.artwork
					song.duration = Double(track.duration ?? 1) / 1000
				}
				song.appName = app.name
				song.position = spotify.playerPosition
				song.state = spotify.playerState == .playing ? .playing : .paused
			}
		} else {
			let appleMusic = MusicApp.music.sbApp as! MusicApplication
			if appleMusic.isRunning {
				let track: MusicTrack = appleMusic.currentTrack!
				if !(song.id == (track.name ?? "") + (track.artist ?? "")) {
					song.title = track.name ?? ""
					song.artist = track.artist ?? ""
					song.albumArt = (track.artworks?().get()?.first as! MusicArtwork).data
					song.duration = track.duration
				}
				song.appName = app.name
				song.position = appleMusic.playerPosition
				song.state = appleMusic.playerState == .playing ? .playing : .paused
			}
		}
	}

	/// Checks if the specified music application is currently running.
	static func isAppRunning(_ app: MusicApp) -> Bool {
		NSWorkspace.shared.runningApplications.contains {
			$0.localizedName == app.name
		}
	}

	/// Executes the provided AppleScript and returns the trimmed result.
	@discardableResult
	static func runAppleScript(_ script: String) -> String? {
		guard let appleScript = NSAppleScript(source: script) else {
			return nil
		}
		var error: NSDictionary?
		let outputDescriptor = appleScript.executeAndReturnError(&error)
		if let error = error {
			print("AppleScript Error: \(error)")
			return nil
		}
		return outputDescriptor.stringValue?.trimmingCharacters(
			in: .whitespacesAndNewlines
		)
	}

	/// Returns the first running music application.
	static func activeMusicApp() -> MusicApp? {
		MusicApp.allCases.first { isAppRunning($0) }
	}

	/// Executes a playback command for the active music application.
	static func executeCommand(_ command: (MusicApp) -> String) {
		guard let activeApp = activeMusicApp() else { return }
		_ = runAppleScript(command(activeApp))
	}
}

// MARK: - Now Playing Manager

/// An observable manager that periodically updates the now playing song.
final class NowPlayingManager: ObservableObject {
	static let shared = NowPlayingManager()

	@Published private(set) var nowPlaying: NowPlayingSong?
	private var cancellable: AnyCancellable?

	private init() {
		cancellable = Timer.publish(every: 0.3, on: .main, in: .common)
			.autoconnect()
			.sink { [weak self] _ in
				self?.updateNowPlaying()
			}
	}

	/// Updates the now playing song asynchronously.
	private func updateNowPlaying() {
		DispatchQueue.main.async {
			NowPlayingProvider.fetchNowPlaying(&self.nowPlaying)
		}
	}

	/// Skips to the previous track.
	func previousTrack() {
		NowPlayingProvider.activeMusicApp()?.sbApp.previousTrack?()
	}

	/// Toggles between play and pause.
	func togglePlayPause() {
		NowPlayingProvider.activeMusicApp()?.sbApp.playpause?()
	}

	/// Skips to the next track.
	func nextTrack() {
		NowPlayingProvider.activeMusicApp()?.sbApp.nextTrack?()
	}
}
