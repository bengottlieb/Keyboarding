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
//  Nothing here depends on typing assist. The keys are laid out and hit-tested
//  identically whether or not a next-key provider is installed; assist is a
//  single substitution at commit. That keeps the keyboard from rebuilding (and
//  reinstalling 30 gestures) on every keystroke, and keeps a deliberate press
//  landing on the key the user aimed at.
//

import SwiftUI
import Suite

public struct KeyboardView: View {
	var keymap: Keymap = .qwertyWithDismiss
	public var id: String { "\(keymap)" }
	@FocusState var isFocused: Bool
	@Environment(\.sendKey) var sendKey
	@Environment(\.keyboardStyle) var kbStyle
	// Read but never called during `body` — see NextKeyProvider.
	@Environment(\.keyboardNextKey) var nextKey
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

	public var body: some View {
		GeometryReader { geo in
			let metrics = KeyboardMetrics(keymap: keymap, width: geo.size.width, keyCapHeight: keyCapHeight,
			                              horizontalMargin: keyboardHorizontalMargins)
			ZStack(alignment: .topLeading) {
				Rectangle()
					.fill(.clear)
					.frame(height: keyCapHeight * CGFloat(keymap.rows.count) + 24)

				ForEach(keymap.rows.indices, id: \.self) { y in
					ForEach(keymap.rows[y].indices, id: \.self) { x in
						let def = keymap.rows[y][x]
						let rect = metrics.rect(forColumn: x, row: y)
						KeyCapView(definition: def)
							.frame(width: rect.width, height: rect.height)
							// Keys can be far wider than tall (iPad): size the glyphs from the
							// smaller dimension so they never overflow into neighboring rows.
							.font(kbStyle.keyFont.font(size: min(metrics.keyCapWidth, metrics.keyCapHeight) * 0.5))
							.contentShape(.rect)
							.gesture(keyDrag(from: def, metrics: metrics))
							.accessibilityAddTraits(.isButton)
							.accessibilityAction { commit(def) }
							.offset(x: rect.minX, y: rect.minY)
					}
				}

				#if DEBUG
					AssistRegionOverlay(metrics: metrics).zIndex(150)
				#endif

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
	private func keyDrag(from origin: KeyDefinition, metrics: KeyboardMetrics) -> some Gesture {
		let glideEligible = glideHandler != nil && origin.type == .letter
		return DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
			.onChanged { value in
				let target = metrics.key(at: value.location)
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
					if let target = metrics.key(at: value.location) {
						commit(assisted(target, at: value.location, origin: origin, metrics: metrics))
					}
				}
			}
	}

	/// Typing assist, the whole of it: a letter key released during a fast burst,
	/// without being held or slid, close enough to the expected letter, becomes
	/// that letter. Anything deliberate — a pause to think, a held key, a finger
	/// that slid to aim — types exactly what it landed on.
	private func assisted(_ target: KeyDefinition, at point: CGPoint, origin: KeyDefinition, metrics: KeyboardMetrics) -> KeyDefinition {
		defer { if target.type == .letter { touches.recordCommit(origin: origin) } }
		guard target.type == .letter, touches.allowsAssist(origin: origin),
		      let letter = nextKey?(), let assistKey = self.key(forLetter: letter) else { return target }
		return metrics.assisted(target, at: point, assistKey: assistKey,
		                        expansion: metrics.keyCapWidth * kbStyle.nextKeyHitExpansion)
	}

	private func key(forLetter letter: String) -> KeyDefinition? {
		keymap.rows.joined().first { $0.string?.uppercased() == letter.uppercased() }
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

#if DEBUG
	/// Debug only: outlines the region where a fast-burst slip is corrected toward
	/// the expected letter. Its own view so that asking the host for that letter —
	/// which changes on every keystroke — invalidates this overlay alone and not
	/// the keycaps.
	private struct AssistRegionOverlay: View {
		let metrics: KeyboardMetrics
		@Environment(\.keyboardNextKey) private var nextKey
		@Environment(\.keyboardAssistDebug) private var assistDebug
		@Environment(\.keyboardStyle) private var kbStyle

		var body: some View {
			if assistDebug, let letter = nextKey?(),
			   let key = metrics.keymap.rows.joined().first(where: { $0.string?.uppercased() == letter.uppercased() }),
			   let rect = metrics.rect(for: key) {
				let expansion = metrics.keyCapWidth * kbStyle.nextKeyHitExpansion
				let region = rect.insetBy(dx: -expansion / 2, dy: -expansion / 2)
				RoundedRectangle(cornerRadius: kbStyle.cornerRadius)
					.fill(Color.accentColor.opacity(0.2))
					.overlay(RoundedRectangle(cornerRadius: kbStyle.cornerRadius).strokeBorder(Color.accentColor, lineWidth: 2))
					.frame(width: region.width, height: region.height)
					.position(x: region.midX, y: region.midY)
					.allowsHitTesting(false)
			}
		}
	}
#endif

#Preview {
	GeometryReader { geo in
		VStack {
			Spacer()
			KeyboardView()
		}
	}
}
