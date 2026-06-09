//
//  MusicProvider.swift
//  Barik
//
//  Created by josh on 6/8/26.
//
import ScriptingBridge
import AppKit

class MusicProvider: NowPlayingProvider {
	private var sbApp: MusicApplication
	
	var name = "Music"
	var bundleID = "com.apple.Music"
	var isRunning: Bool { sbApp.isRunning }
	var notificationName = Notification.Name("com.apple.Music.playerInfo")
	
	required init?() {
		guard let app = SBApplication(bundleIdentifier: bundleID) else { return nil }
		self.sbApp = app
	}

	func playPause() { sbApp.playpause?() }
	func nextTrack() { sbApp.nextTrack?() }
	func prevTrack() { sbApp.previousTrack?() }
	func seek(to time: TimeInterval) { sbApp.setPlayerPosition?(time) }
	var position: TimeInterval? { sbApp.playerPosition }
	var state: PlaybackState { .standard(value: sbApp.playerState?.rawValue) ?? .stopped }
	var nowPlaying: NowPlayingSong? {
		guard let track: MusicTrack = sbApp.currentTrack else { return nil }
		return NowPlayingSong(
			appName: name,
			title: track.name,
			artist: track.artist,
			albumArt: (track.artworks?().firstObject as? MusicArtwork)?.data,
			duration: track.duration
		)
	}
}
