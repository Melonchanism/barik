import AppKit
import Combine
import SwiftUI

// MARK: - Image Cache

/// A singleton cache for storing downloaded NSImage objects.
final class ImageCache {
	static let shared = NSCache<NSString, NSImage>()
}

// MARK: - Image Loader

/// An observable object that asynchronously downloads and caches images.
final class ImageLoader: ObservableObject {
	@Published var image: NSImage?

	private var cancellable: AnyCancellable?

	/// The URL of the image to load.
	var url: URL?

	/// Optional target size to which the image should be resized.
	var targetSize: CGSize?

	/// Initializes the loader with an optional URL and target size.
	/// - Parameters:
	///   - url: The URL of the image.
	///   - targetSize: The desired size for the image.
	init(url: URL?, targetSize: CGSize? = nil) {
		self.url = url
		self.targetSize = targetSize
	}

	/// Generates a cache key based on the URL and target size.
	private var cacheKey: NSString? {
		guard let url = url else { return nil }
		if let targetSize = targetSize {
			return "\(url.absoluteString)-\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
		} else {
			return url.absoluteString as NSString
		}
	}

	/// Loads the image from the URL, resizing if needed, and caches it.
	func load() {
		// Cancel any ongoing request before starting a new one.
		cancellable?.cancel()

		guard let url = url, let key = cacheKey else { return }

		// Check for cached image.
		if let cachedImage = ImageCache.shared.object(forKey: key) {
			self.image = cachedImage
			return
		}

		// Download image asynchronously.
		cancellable = URLSession.shared.dataTaskPublisher(for: url)
			.tryMap { [weak self] data, _ -> NSImage? in
				guard let downloadedImage = NSImage(data: data) else { return nil }
				if let targetSize = self?.targetSize {
					return downloadedImage.resized(to: targetSize) ?? downloadedImage
				}
				return downloadedImage
			}
			.replaceError(with: nil)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] downloadedImage in
				if let downloadedImage = downloadedImage {
					ImageCache.shared.setObject(downloadedImage, forKey: key)
				}
				self?.image = downloadedImage
			}
	}

	deinit {
		cancellable?.cancel()
	}
}

// MARK: - NSImage Extension

extension NSImage {
	/// Returns a resized version of the image.
	/// - Parameter newSize: The target size.
	/// - Returns: A new NSImage resized to the given dimensions, or nil if resizing fails.
	func resized(to newSize: NSSize) -> NSImage? {
		let newImage = NSImage(size: newSize)
		newImage.lockFocus()
		let rect = NSRect(origin: .zero, size: newSize)
		self.draw(
			in: rect,
			from: NSRect(origin: .zero, size: self.size),
			operation: .copy,
			fraction: 1.0
		)
		newImage.unlockFocus()
		newImage.size = newSize
		return newImage
	}
}

// MARK: Roate Animated Image

struct RotateAnimatedImage<RotatingContent: View>: View {
	let image: NSImage?

	@State private var displayedImage: NSImage?
	@State private var rotation: Double = 1
	@State private var transitioning: Bool = false
	let rotatingModifier: (Image) -> RotatingContent

	/// Initializes the view with a URL, optional target size, and a custom rotating modifier.
	init(image: NSImage?, @ViewBuilder rotatingModifier: @escaping (Image) -> RotatingContent) {
		self.image = image
		self.rotatingModifier = rotatingModifier
	}

	/// Convenience initializer when no custom modifier is needed.
	init(image: NSImage?) where RotatingContent == Image {
		self.init(image: image) { $0 }
	}

	var body: some View {
		Group {
			if let image = displayedImage {
				rotatingModifier(Image(nsImage: image).resizable())
					.blur(radius: abs(1 - rotation) * 5)
					.scaleEffect(x: rotation)
			} else {
				Color.clear
			}
		}
		.onAppear {
			displayedImage = image
		}
		.onChange(of: image) {
			guard let newImage = image else { return }
			// If image is loading for the first time.
			if transitioning { return }
			if displayedImage == nil {
				displayedImage = newImage
			} else if displayedImage != newImage {
				// Animate the transition.
				transitioning = true
				withAnimation(.easeInOut(duration: 0.2)) { rotation = 0 }
				withAnimation(.easeOut(duration: 0.3).delay(0.2)) { rotation = 1 }
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
					displayedImage = newImage
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
					transitioning = false
				}
			}
		}
	}
}

// MARK: - Cached Image View

/// A view that displays a cached image without animation.
struct CachedImage<Content: View>: View {
	let url: URL?
	let targetSize: CGSize?

	@StateObject private var loader: ImageLoader
	@State private var displayedImage: NSImage?
	let content: (Image) -> Content

	/// Initializes the view with a URL and optional target size.
	init(
		url: URL?,
		targetSize: CGSize? = nil,
		@ViewBuilder content: @escaping (Image) -> Content
	) {
		self.url = url
		self.targetSize = targetSize
		_loader = StateObject(wrappedValue: ImageLoader(url: url, targetSize: targetSize))
		self.content = content
	}

	var body: some View {
		Group {
			if let image = displayedImage {
				Image(nsImage: image).resizable()
			} else {
				Color.clear
			}
		}
		.onAppear { loader.load() }
		.onReceive(loader.$image) { newImage in
			displayedImage = newImage
		}
		.onChange(of: url) { _, newURL in
			loader.url = newURL
			loader.load()
		}
	}
}
