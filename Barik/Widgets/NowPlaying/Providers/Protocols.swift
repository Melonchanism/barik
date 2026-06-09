//
//  SBProtocol.swift
//  Barik
//
//  Created by josh on 6/3/26.
//

import ScriptingBridge

@objc public protocol SBObjectProtocol: NSObjectProtocol {
	func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
	func activate()
	@objc optional func reopen()
	var delegate: SBApplicationDelegate! { get set }
	var isRunning: Bool { get }
}

// Functions that exist on BOTH spotify and apple music (subject to change with additionall apps)
@objc public protocol SBMusicApplicationProtocol: SBApplicationProtocol {
	// Common properties
	@objc optional var currentTrack: SBObject { get }        // currently playing track (concrete type varies by app)
	@objc optional var soundVolume: Int { get }              // sound output volume (0 = min, 100 = max)
	@objc optional var playerState: Int { get }              // player state enum (stopped/paused/playing) — use app-specific enum
	@objc optional var playerPosition: Double { get }        // position in seconds within current track
	@objc optional var name: String { get }                  // application name
	@objc optional var frontmost: Bool { get }               // is this the active application?
	@objc optional var version: String { get }               // application version
	
	// Common playback control methods
	@objc optional func play()                                // resume playback
	@objc optional func pause()                               // pause playback
	@objc optional func playpause()                           // toggle play/pause
	@objc optional func nextTrack()                           // skip to next track
	@objc optional func previousTrack()                       // skip to previous track
	@objc optional func setSoundVolume(_ soundVolume: Int)    // set volume (0 = min, 100 = max)
	@objc optional func setPlayerPosition(_ playerPosition: Double) // seek to position in seconds
}

protocol NowPlayingProvider {
	var name: String { get }
	var bundleID: String { get }
	var isRunning: Bool { get }
	var notificationName: NSNotification.Name { get }
	
	init?()
	
	func playPause()
	func nextTrack()
	func prevTrack()
	func seek(to: TimeInterval)
	var position: TimeInterval? { get }
	var state: PlaybackState { get }
	var nowPlaying: NowPlayingSong? { get }
}
