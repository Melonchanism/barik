import SwiftUI
import SmoothGradient

struct BackgroundView: View {
	@ObservedObject var configManager = ConfigManager.shared
	var height: CGFloat? { configManager.config.experimental.background.resolvedHeight }
	var theme: ColorScheme? {
		switch configManager.config.rootToml.theme {
		case "dark": return .dark
		case "light": return .light
		default: return nil
		}
	}

	private var background: AnyShapeStyle {
		switch configManager.config.experimental.background.type {
		case .black:
			AnyShapeStyle(.black)
		case .blur:
			AnyShapeStyle(configManager.config.experimental.background.blur)
		case .vignette:
			AnyShapeStyle(
				SmoothLinearGradient(
					from: .shadow, to: .clear,
					startPoint: .top,
					endPoint: .bottom
				))
		}
	}

	var body: some View {
		if configManager.config.experimental.background.displayed {
			Rectangle()
				.fill(background)
				.frame(height: height)
				.preferredColorScheme(theme)
		}
	}
}
