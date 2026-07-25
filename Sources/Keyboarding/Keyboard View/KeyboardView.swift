//
//  KeyboardView.swift
//
//
//  Created by Ben Gottlieb on 8/15/23.
//
//  Keys behave like the system keyboard: touch-down pops a preview bubble over
//  the key under the finger, sliding retargets it, and the key only commits on
//  touch-up — so a mistaken touch can move to the right key (or well off the
//  keyboard to cancel) before letting go.
//

import SwiftUI
import Suite

public struct KeyboardView: View {
	var keymap: Keymap = .qwertyWithDismiss
	public var id: String { "\(keymap)" }
	@FocusState var isFocused: Bool
	@Environment(\.sendKey) var sendKey
	@Environment(\.keyboardStyle) var kbStyle
	@Environment(\.keyboardNextKey) var nextKey
	@Environment(\.keyboardAssistDebug) var assistDebug
	@Environment(\.keyboardGlide) var glideHandler

	// Live-touch state. Deliberately NOT read in this body — only the touch
	// overlay observes it, so fingers going down and sliding never re-render
	// the keycaps (each keycap runs its own drag gesture, so rolling
	// multi-finger typing tracks independently).
	@State private var touches = KeyboardTouchModel()

	private static let space = "Keyboarding.KeyboardView"

	public init(keymap: Keymap? = nil) {
		self.keymap = keymap ?? .qwertyWithDismiss
	}

	var keyboardHorizontalMargins: CGFloat { 8 }

	#if os(iOS)
		// Size class, not UIDevice.orientation: orientation is unknown at first
		// render (and faceUp/faceDown lie), which left iPads with mismatched rows.
		@Environment(\.verticalSizeClass) private var verticalSizeClass
	#endif

	var keyCapHeight: CGFloat {
		#if os(iOS)
			verticalSizeClass == .compact ? 44 : 54
		#else
			54
		#endif
	}

	// The frame follows the rows (top padding + rows + breathing room), so wide
	// devices don't clip the bottom row against a hard-coded height.
	var keyboardHeight: CGFloat {
		keyCapHeight * CGFloat(keymap.rows.count) + 24
	}

	private var assistKey: KeyDefinition? {
		guard let nextKey else { return nil }
		return keymap.rows.joined().first { $0.string?.uppercased() == nextKey.uppercased() }
	}

	public var body: some View {
		GeometryReader { geo in
			let metrics = KeyboardMetrics(keymap: keymap, width: geo.size.width, keyCapHeight: keyCapHeight,
			                              horizontalMargin: keyboardHorizontalMargins)
			let assistKey = assistKey
			let assistExpansion = assistKey == nil ? 0 : metrics.keyCapWidth * kbStyle.nextKeyHitExpansion
			ZStack(alignment: .topLeading) {
				Rectangle()
					.fill(.clear)
					.frame(height: keyCapHeight * CGFloat(keymap.rows.count) + 24)

				ForEach(keymap.rows.indices, id: \.self) { y in
					ForEach(keymap.rows[y].indices, id: \.self) { x in
						let def = keymap.rows[y][x]
						// Typing assist: enlarge the hit target of the key matching the
						// expected next letter so off-boundary ("fat finger") taps still land
						// on it. The visible keycap is unchanged; the frame (and hit-testing)
						// grows and floats above its neighbors via zIndex.
						let isNext = def == assistKey
						let currentPadding = isNext ? assistExpansion : 0
						let rect = metrics.rect(forColumn: x, row: y)
						KeyCapView(definition: def)
							.padding(currentPadding / 2)
							.frame(width: rect.width + currentPadding, height: rect.height + currentPadding)
							// Keys can be far wider than tall (iPad): size the glyphs from the
							// smaller dimension so they never overflow into neighboring rows.
							.font(kbStyle.keyFont.font(size: min(metrics.keyCapWidth, metrics.keyCapHeight) * 0.5))
							.overlay {
								if isNext && assistDebug {
									RoundedRectangle(cornerRadius: kbStyle.cornerRadius)
										.fill(Color.accentColor.opacity(0.2))
										.overlay(RoundedRectangle(cornerRadius: kbStyle.cornerRadius).strokeBorder(Color.accentColor, lineWidth: 2))
										.allowsHitTesting(false)
								}
							}
							.contentShape(.rect)
							.gesture(keyDrag(from: def, metrics: metrics, assistKey: assistKey, assistExpansion: assistExpansion))
							.accessibilityAddTraits(.isButton)
							.accessibilityAction { commit(def) }
							.zIndex(isNext ? 100 : 0)
							.offset(x: rect.minX - currentPadding / 2, y: rect.minY - currentPadding / 2)
					}
				}

				KeyboardTouchOverlay(touches: touches, metrics: metrics)
					.zIndex(200)
			}
			.coordinateSpace(name: Self.space)
			.padding(.top, 12)
			.ignoresSafeArea(edges: .leading)
		}
		.frame(maxWidth: .infinity)
		.frame(height: keyboardHeight)
		.background(kbStyle.background)
		.focusable()
		.onAppear { isFocused = true }
		.focused($isFocused)
		.onKeyPress { key in
			sendKey(.init(keyPress: key))
		}
	}

	// The keyboard-space drag each keycap starts: retarget to whatever key is
	// under the finger as it moves, commit that key on touch-up. Keyed by the
	// origin key so simultaneous fingers don't fight over one entry.
	//
	// With a glide handler installed and a letter-key origin, the same drag also
	// records a glide path; once it traverses a second letter the touch *is* a
	// glide — release delivers the stroke to the handler instead of committing
	// the key under the finger. Single-key touches still tap normally.
	private func keyDrag(from origin: KeyDefinition, metrics: KeyboardMetrics, assistKey: KeyDefinition?, assistExpansion: CGFloat) -> some Gesture {
		let glideEligible = glideHandler != nil && origin.type == .letter
		return DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
			.onChanged { value in
				let target = metrics.key(at: value.location, assistKey: assistKey, assistExpansion: assistExpansion)
				touches.update(origin: origin, target: target, click: kbStyle.enableKeySounds)
				if glideEligible { touches.glideSample(origin: origin, point: value.location, over: target) }
			}
			.onEnded { value in
				if let capture = touches.endGlide(origin: origin), capture.isGliding {
					// No linger: a glide never showed a bubble, so none should flash now.
					touches.update(origin: origin, target: nil, click: false)
					glideHandler?(GlideStroke(points: capture.points, tracedLetters: capture.letters,
					                          geometry: GlideGeometry(keymap: keymap, metrics: metrics)))
				} else {
					touches.end(origin: origin)
					if let target = metrics.key(at: value.location, assistKey: assistKey, assistExpansion: assistExpansion) {
						commit(target)
					}
				}
			}
	}

	private func commit(_ key: KeyDefinition) {
		switch key.type {
		case .dismiss:
			// The host gets first crack at dismiss (e.g. hiding its own keyboard
			// view); only an unhandled dismiss falls back to ending editing.
			if sendKey(key) == .handled { return }
			#if os(iOS)
				UIView.resignAllFirstResponders()
			#endif

		default:
			_ = sendKey(key)
		}
	}

}

#Preview {
	GeometryReader { geo in
		VStack {
			Spacer()
			KeyboardView()
		}
	}
}
