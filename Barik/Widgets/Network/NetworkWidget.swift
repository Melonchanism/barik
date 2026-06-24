import SwiftUI

/// Widget for the menu, displaying Wi‑Fi and Ethernet icons.
struct NetworkWidget: View {
	@ObservedObject private var viewModel = NetworkStatusViewModel.shared
	@State private var rect: CGRect = .zero

	var body: some View {
		BarWidget(id: "network", popup: { NetworkPopup() }) {
			HStack(spacing: 15) {
				if viewModel.wifiState != .notSupported {
					AnyView(wifiIcon)
				}
				if viewModel.ethernetState != .notSupported {
					AnyView(ethernetIcon)
				}
			}
			.bold()
		}
		.font(.system(size: 15))
		.experimentalConfiguration(cornerRadius: 15)
		.frame(maxHeight: .infinity)
	}

	private var wifiIcon: any View {
		if viewModel.ssid == "Not connected" {
			return Image(systemName: "wifi.slash")
				.foregroundColor(.red)
		}
		switch viewModel.wifiState {
		case .connected:
			return Image(systemName: "wifi")
		case .connecting:
			return Image(systemName: "wifi")
				.foregroundColor(.yellow)
		case .connectedWithoutInternet:
			return Image(systemName: "wifi.exclamationmark")
				.foregroundColor(.yellow)
		case .disconnected:
			return Image(systemName: "wifi.slash")
				.foregroundColor(.gray)
		case .disabled:
			return Image(systemName: "wifi.slash")
				.foregroundColor(.red)
		default:
			return Image(systemName: "questionmark")
		}
	}

	private var ethernetIcon: any View {
		switch viewModel.ethernetState {
		case .connected:
			Image(systemName: "network")
				.foregroundColor(.primary)
		case .connectedWithoutInternet:
			Image(systemName: "network")
				.foregroundColor(.yellow)
		case .connecting:
			Image(systemName: "network.slash")
				.foregroundColor(.yellow)
		case .disconnected:
			Image(systemName: "network.slash")
				.foregroundColor(.red)
		case .disabled, .notSupported:
			Image(systemName: "questionmark.circle")
				.foregroundColor(.gray)
		}
	}
}

struct NetworkWidget_Previews: PreviewProvider {
	static var previews: some View {
		NetworkWidget()
			.frame(width: 200, height: 100)
			.background(Color.black)
	}
}
