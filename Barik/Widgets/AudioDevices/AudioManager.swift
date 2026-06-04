//
//  Untitled.swift
//  Barik
//
//  Created by josh on 6/4/26.
//

import Cocoa
import CoreAudio
import CoreServices

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
	static var streamConfiguration = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyStreamConfiguration,
		mScope: kAudioDevicePropertyScopeInput,
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
	static var pan = AudioObjectPropertyAddress(
		mSelector: kAudioDevicePropertyStereoPan,
		mScope: kAudioObjectPropertyScopeOutput,
		mElement: kAudioObjectPropertyElementMain
	)
}

var systemObject = AudioObjectID(kAudioObjectSystemObject)

class AudioManager: ObservableObject {
	@Published var volume: Float32?
	@Published var outputDeviceName: String?

	fileprivate var currentDevice: AudioDeviceID?

	init() {
		AudioObjectAddPropertyListener(
			systemObject,
			&AOAddress.outputDevice,
			updateValue,
			Unmanaged.passUnretained(self).toOpaque()
		)

		updateValue(0, 0, &AOAddress.pan, Unmanaged.passUnretained(self).toOpaque())
	}
}

private func updateValue(
	_ inObjectID: AudioObjectID,
	_ inAddresses: UInt32,
	_ address: UnsafePointer<AudioObjectPropertyAddress>,
	_ context: UnsafeMutableRawPointer?
) -> Int32 {
	let manager = Unmanaged<AudioManager>.fromOpaque(context!).takeUnretainedValue()
	let device: AudioDeviceID? = getData(from: systemObject, &AOAddress.outputDevice)
	DispatchQueue.main.async {
		if manager.currentDevice != device {
			if manager.currentDevice != nil {
				AudioObjectRemovePropertyListener(
					manager.currentDevice!,
					&AOAddress.outputVolume,
					updateValue,
					Unmanaged.passUnretained(manager).toOpaque()
				)
			}
			AudioObjectAddPropertyListener(
				device!,
				&AOAddress.outputVolume,
				updateValue,
				Unmanaged.passUnretained(manager).toOpaque()
			)
		}
		manager.currentDevice = device
		manager.outputDeviceName =
			getData(from: device!, &AOAddress.name, nilValue: "" as CFString) as? String
		manager.volume = getData(from: device!, &AOAddress.outputVolume, nilValue: Float32(0))
	}
	return 0
}

private func getData<T>(
	from object: AudioObjectID,
	_ address: inout AudioObjectPropertyAddress,
	nilValue: T? = nil
)
	-> T?
{
	var size: UInt32 = 0
	var data: T? = nilValue
	AudioObjectGetPropertyDataSize(object, &address, 0, nil, &size)
	AudioObjectGetPropertyData(object, &address, 0, nil, &size, &data)
	return data!
}
