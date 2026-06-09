//
//  Untitled.swift
//  Barik
//
//  Created by josh on 6/4/26.
//

import Cocoa
import CoreAudio
import CoreServices

// MARK: Audio Device
class AudioDevice: Equatable, Hashable, Identifiable {
	var name: String
	var id: AudioObjectID

	enum VolumeType {
		case output, channel, none
	}

	var volumeType: VolumeType
	var canSetVolume: Bool { volumeType != .none }
	var transportType: UInt32
	var iconURL: URL

	var outChannelCount: Int
	var inChannelCount: Int
	var hasOutput: Bool { outChannelCount > 0 }
	var hasInput: Bool { inChannelCount > 0 }

	init(id: AudioObjectID) {
		self.id = id
		self.name = getData(of: id, AOAddress.name, nilValue: "" as CFString) as String
		var channel1 = AOAddress.outputVolume(for: 1)

		if getIsSettable(of: id, AOAddress.outputVolume) {
			self.volumeType = .output
		} else if getIsSettable(of: id, channel1) {
			self.volumeType = .channel
		} else {
			self.volumeType = .none
		}

		self.transportType = getData(of: id, AOAddress.transportType, nilValue: 0)
		// There is no null value for a URL
		self.iconURL = getData(of: id, AOAddress.icon, nilValue: URL(string: "a")!)

		var size = getSize(of: id, AOAddress.outStreamConfiguration)
		let bufferList = AudioBufferList.allocate(maximumBuffers: Int(size))
		AudioObjectGetPropertyData(
			id, &AOAddress.outStreamConfiguration, 0, nil, &size, bufferList.unsafeMutablePointer)
		outChannelCount = Int(bufferList.reduce(UInt32(0)) { $0 + $1.mNumberChannels })
		free(bufferList.unsafeMutablePointer)

		var size2 = getSize(of: id, AOAddress.inStreamConfiguration)
		let bufferList2 = AudioBufferList.allocate(maximumBuffers: Int(size))
		AudioObjectGetPropertyData(
			id, &AOAddress.inStreamConfiguration, 0, nil, &size2, bufferList2.unsafeMutablePointer)
		inChannelCount = Int(bufferList2.reduce(UInt32(0)) { $0 + $1.mNumberChannels })
		free(bufferList2.unsafeMutablePointer)
	}

	static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

private var systemObject = AudioObjectID(kAudioObjectSystemObject)

class AudioManager: ObservableObject {
	static var shared = AudioManager()

	var ptr: UnsafeMutableRawPointer { Unmanaged.passUnretained(self).toOpaque() }

	@Published var volume: Float32?
	@Published var outputDevice: AudioDevice?
	@Published var devices: [AudioDevice]

	init() {
		devices = []
		AudioObjectAddPropertyListener(systemObject, &AOAddress.outputDevice, updateValue, ptr)
		AudioObjectAddPropertyListener(systemObject, &AOAddress.allDevices, updateDevices, ptr)

		updateDevices(0, 0, &AOAddress.outputDevice, ptr)
		updateValue(0, 0, &AOAddress.outputVolume, ptr)
	}

	deinit {
		AudioObjectRemovePropertyListener(systemObject, &AOAddress.outputDevice, updateValue, ptr)
		AudioObjectRemovePropertyListener(systemObject, &AOAddress.allDevices, updateDevices, ptr)
		AudioObjectRemovePropertyListener(outputDevice!.id, &AOAddress.outputVolume, updateValue, ptr)
		var address = AOAddress.outputVolume(for: 1)
		AudioObjectRemovePropertyListener(outputDevice!.id, &address, updateValue, ptr)
	}

	func setOutput(device: AudioDevice) {
		setData(of: systemObject, AOAddress.outputDevice, value: device.id)
	}

	func setVolume(_ value: Float32) {
		guard let outputDevice = outputDevice else { return }
		switch outputDevice.volumeType {
		case .output:
			// Volume set to 0 is also mute, so the mute property is almost useless
			setData(of: outputDevice.id, AOAddress.mute, value: 0)
			setData(of: outputDevice.id, AOAddress.outputVolume, value: value)
			break
		case .channel:
			for i in 1...outputDevice.outChannelCount {
				var address = AOAddress.outputVolume(for: i)
				setData(of: outputDevice.id, address, value: value)
			}
			break
		default:
			break
		}
	}
}

// MARK: Listener Callbacks
@discardableResult
private func updateDevices(
	_ inObjectID: AudioObjectID,
	_ inAddresses: UInt32,
	_ address: UnsafePointer<AudioObjectPropertyAddress>,
	_ context: UnsafeMutableRawPointer?
) -> Int32 {
	let manager = Unmanaged<AudioManager>.fromOpaque(context!).takeUnretainedValue()

	var size = getSize(of: systemObject, AOAddress.allDevices)
	var deviceIDs: [AudioDeviceID] = Array(
		repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
	AudioObjectGetPropertyData(systemObject, &AOAddress.allDevices, 0, nil, &size, &deviceIDs)

	manager.devices = deviceIDs.map { AudioDevice(id: $0) }
	return 0
}

@discardableResult
private func updateValue(
	_ inObjectID: AudioObjectID,
	_ inAddresses: UInt32,
	_ address: UnsafePointer<AudioObjectPropertyAddress>,
	_ context: UnsafeMutableRawPointer?
) -> Int32 {
	let manager = Unmanaged<AudioManager>.fromOpaque(context!).takeUnretainedValue()
	let device: AudioDeviceID? = getData(of: systemObject, AOAddress.outputDevice, nilValue: .zero)
	DispatchQueue.asyncIfNeeded {
		if manager.outputDevice?.id != device {
			var address = AOAddress.outputVolume(for: 1)
			if manager.outputDevice != nil {
				AudioObjectRemovePropertyListener(
					manager.outputDevice!.id, &AOAddress.outputVolume, updateValue, manager.ptr)
				AudioObjectRemovePropertyListener(
					manager.outputDevice!.id, &address, updateValue, manager.ptr)
			}
			AudioObjectAddPropertyListener(device!, &AOAddress.outputVolume, updateValue, manager.ptr)
			AudioObjectAddPropertyListener(device!, &address, updateValue, manager.ptr)
		}
		manager.outputDevice = AudioDevice(id: device!)
		if manager.outputDevice?.volumeType == .output {
			manager.volume = getData(of: device!, AOAddress.outputVolume, nilValue: 0)
		} else if manager.outputDevice?.volumeType == .channel {
			manager.volume = getData(of: device!, AOAddress.outputVolume(for: 1), nilValue: 0)
		} else {
			manager.volume = nil
		}
	}
	return 0
}

// MARK: Helpers
// Helper methods for staticaly allocated values
private func getSize(of object: AudioObjectID, _ address: AudioObjectPropertyAddress)
	-> UInt32
{
	var size: UInt32 = 0
	var address = address
	AudioObjectGetPropertyDataSize(object, &address, 0, nil, &size)
	return size
}

private func getData<T>(
	of object: AudioObjectID, _ address: AudioObjectPropertyAddress, nilValue: T
)
	-> T
{
	var size: UInt32 = 0
	var data = nilValue
	var address = address
	AudioObjectGetPropertyDataSize(object, &address, 0, nil, &size)
	AudioObjectGetPropertyData(object, &address, 0, nil, &size, &data)
	return data
}

private func getIsSettable(of object: AudioObjectID, _ address: AudioObjectPropertyAddress)
	-> Bool
{
	var address = address
	var canSet: DarwinBoolean = false
	AudioObjectIsPropertySettable(object, &address, &canSet)
	return canSet.boolValue
}

private func setData<T>(of object: AudioObjectID, _ address: AudioObjectPropertyAddress, value: T) {
	var address = address
	var value = value
	AudioObjectSetPropertyData(
		object, &address, 0, nil, UInt32(MemoryLayout.size(ofValue: value)), &value
	)
}

// MARK: AudioObjectPropertyAddress
// Exclusive Memory access had to be disabled, as these are treated as constants but still must be pointers
struct AOAddress {
	static var outputDevice = AudioObjectPropertyAddress(
		mSelector: kAudioHardwarePropertyDefaultOutputDevice,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	static var inputDevice = AudioObjectPropertyAddress(
		mSelector: kAudioHardwarePropertyDefaultInputDevice,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	static var allDevices = AudioObjectPropertyAddress(
		mSelector: kAudioHardwarePropertyDevices,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	static var name = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyDeviceNameCFString,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	static var inStreamConfiguration = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyStreamConfiguration,
		mScope: kAudioDevicePropertyScopeInput,
		mElement: kAudioObjectPropertyElementMain
	)
	static var outStreamConfiguration = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyStreamConfiguration,
		mScope: kAudioDevicePropertyScopeOutput,
		mElement: kAudioObjectPropertyElementMain
	)
	static var sampleRate = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyNominalSampleRate,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	static var supportedSampleRates = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyAvailableNominalSampleRates,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	static var outputVolume = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyVolumeScalar,
		mScope: kAudioObjectPropertyScopeOutput,
		mElement: kAudioObjectPropertyElementMain
	)
	static func outputVolume(for channel: Int) -> AudioObjectPropertyAddress {
		return AudioObjectPropertyAddress(
			mSelector: kAudioDevicePropertyVolumeScalar,
			mScope: kAudioObjectPropertyScopeOutput,
			mElement: UInt32(channel)
		)
	}
	static var mute = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyMute,
		mScope: kAudioObjectPropertyScopeOutput,
		mElement: kAudioObjectPropertyElementMain)
	static var pan = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyStereoPan,
		mScope: kAudioObjectPropertyScopeOutput,
		mElement: kAudioObjectPropertyElementMain
	)
	static var icon = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyIcon,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	static var transportType = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyTransportType,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
}
