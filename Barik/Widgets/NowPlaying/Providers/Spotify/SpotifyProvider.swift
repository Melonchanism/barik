//
//  SpotifyProvider.swift
//  Barik
//
//  Created by josh on 6/8/26.
//
import ScriptingBridge
import AppKit

class SpotifyProvider: NowPlayingProvider {
	private var sbApp: SpotifyApplication
	
	var name = "Spotify"
	var bundleID = "com.spotify.client"
	var isRunning: Bool { sbApp.isRunning }
	var notificationName = Notification.Name("com.spotify.client.PlaybackStateChanged")
	
	required init?() {
		guard let app = SBApplication(bundleIdentifier: bundleID) else { return nil }
		self.sbApp = app
	}

	func playPause() { sbApp.playpause?() }
	func nextTrack() { sbApp.nextTrack?() }
	func prevTrack() { sbApp.previousTrack?() }
	func seek(to time: TimeInterval) { sbApp.setPlayerPosition?(time) }
	var position: TimeInterval? { sbApp.playerPosition }
	var state: PlaybackState {
		if !isRunning { return .stopped }
		else { return .standard(value: sbApp.playerState?.rawValue) ?? .stopped }
	}
	var nowPlaying: NowPlayingSong? {
		guard let track: SpotifyTrack = sbApp.currentTrack else { return nil }
		return NowPlayingSong(
			appName: name,
			title: track.name,
			artist: track.artist,
			albumArt: track.artwork,
			duration: Double(track.duration ?? 1) / 1000
		)
	}
}
