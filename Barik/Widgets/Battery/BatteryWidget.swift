import SwiftUI

struct BatteryWidget: View {
	@EnvironmentObject var configProvider: ConfigProvider
	var config: ConfigData { configProvider.config }
	var showPercentage: Bool { config["show-percentage"]?.boolValue ?? true }
	var criticalLevel: Int { config["critical-level"]?.intValue ?? 20 }

	@ObservedObject var batteryManager = BatteryManager.shared

	@State private var rect: CGRect = CGRect()

	var body: some View {
		ZStack {
			ZStack(alignment: .leading) {
				BatteryBodyView(mask: false)
					.opacity(showPercentage ? 0.3 : 0.4)
				BatteryBodyView(mask: true)
					.clipShape(
						Rectangle().path(
							in: CGRect(
								x: showPercentage ? 0 : 2,
								y: 0,
								width: 30 * Int(batteryManager.batteryLevel) / (showPercentage ? 110 : 130),
								height: .bitWidth
							)
						)
					)
					.foregroundStyle(batteryManager.color)
				BatteryText(
					level: batteryManager.batteryLevel,
					isCharging: batteryManager.isCharging,
					isPluggedIn: batteryManager.isPluggedIn
				)
				.foregroundStyle(.background)
			}
			.frame(width: 30, height: 10)
			.background(
				GeometryReader { geometry in
					Color.clear
						.onAppear {
							rect = geometry.frame(in: .global)
						}
						.onChange(of: geometry.frame(in: .global)) {
							oldState,
							newState in
							rect = newState
						}
				}
			)
		}
		.experimentalConfiguration(cornerRadius: 15)
		.frame(maxHeight: .infinity)
		.background(Color.black.opacity(0.001))
		.onTapGesture {
			MenuBarPopup.show(rect: rect, id: "battery") { BatteryPopup() }
		}

	}

	private var batteryTextColor: Color {
		if batteryManager.isCharging {
			return .foregroundOutsideInvert
		} else {
			return batteryManager.isLowPower ? .foregroundOutsideInvert : .black
		}
	}
}

private struct BatteryText: View {
	@EnvironmentObject var configProvider: ConfigProvider
	var config: ConfigData { configProvider.config }
	var showPercentage: Bool { config["show-percentage"]?.boolValue ?? true }

	let level: Int
	let isCharging: Bool
	let isPluggedIn: Bool

	var body: some View {
		HStack(alignment: .center, spacing: -1) {
			if showPercentage {
				Text("\(level)")
					.shadow(color: .primary, radius: 1)
					.font(.system(size: 12))
					.transition(.blurReplace)
			}

			if isCharging && level != 100 {
				Image(systemName: "bolt.fill")
					.font(.system(size: showPercentage ? 8 : 10))
			}

			if !isCharging && isPluggedIn && level != 100 {
				Image(systemName: "powerplug.portrait.fill")
					.font(.system(size: 8))
					.padding(.leading, 1)
			}
		}
		.fontWeight(.semibold)
		.transition(.blurReplace)
		.animation(.smooth, value: isCharging)
		.frame(width: 26, height: 15)
	}
}

private struct BatteryBodyView: View {
	let mask: Bool

	@EnvironmentObject var configProvider: ConfigProvider
	var config: ConfigData { configProvider.config }
	var showPercentage: Bool { config["show-percentage"]?.boolValue ?? true }

	var body: some View {
		ZStack {
			if showPercentage || !mask {
				Image(systemName: "battery.0")
					.resizable()
					.scaledToFit()
			}
			if showPercentage || mask {
				Rectangle()
					.clipShape(RoundedRectangle(cornerRadius: 2))
					.padding(.horizontal, showPercentage ? 3 : 4.4)
					.padding(.vertical, showPercentage ? 2 : 3.5)
					.offset(
						x: showPercentage ? -2 : -1.77,
						y: showPercentage ? 0 : 0.2
					)
			}
		}
		.compositingGroup()
	}
}

struct BatteryWidget_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			BatteryWidget()
		}.frame(width: 200, height: 100)
			.background(.yellow)
			.environmentObject(ConfigProvider(config: [:]))
	}
}
