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
	@Environment(\.scenePhase) private var scenePhase
	@Environment(\.keyboardStyle) var kbStyle
	// Read but never called during `body` — see NextKeyProvider.
	@Environment(\.keyboardNextKey) var nextKey
	@Environment(\.keyboardGlide) var glideHandler
	// Read but never called during `body` — see KeyLongPressHandler.
	@Environment(\.keyLongPress) var keyLongPress

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
							.modifier(keyTouch(from: def, metrics: metrics))
							.allowsHitTesting(def.type != .blank)
							.accessibilityAddTraits(.isButton)
							.accessibilityAction { commit(def) }
							.accessibilityHidden(def.type == .blank)
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
		.onDisappear { touches.cancelAll() }
		.onChange(of: scenePhase) { _, phase in
			if phase != .active { touches.cancelAll() }
		}
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
	//
	// Resting on the key the finger landed on runs the host's long-press block
	// (if it claims that key), which spends the touch: no key commits on release.
	private func keyTouch(from origin: KeyDefinition, metrics: KeyboardMetrics) -> KeyboardKeyTouchLifecycle {
		let glideEligible = glideHandler != nil && origin.type == .letter
		return KeyboardKeyTouchLifecycle(space: Self.space, onChanged: { location, touchID in
				let target = metrics.key(at: location)
				touches.update(origin: origin, target: target, click: kbStyle.enableKeySounds, haptic: kbStyle.enableHaptics, touchID: touchID)
				if let keyLongPress, target == origin { touches.armLongPress(origin: origin) { keyLongPress($0) } }
				if glideEligible { touches.glideSample(origin: origin, point: location, over: target) }
			}, onEnded: { location, touchID in
				guard touches.isActive(origin: origin, touchID: touchID) else { return }
				// A hold that ran the host's block already spent this touch.
				if touches.consumedLongPress(origin: origin) {
					_ = touches.endGlide(origin: origin)
					touches.end(origin: origin)
					return
				}
				if let capture = touches.endGlide(origin: origin), capture.isGliding {
					// No linger: a glide never showed a bubble, so none should flash now.
					touches.update(origin: origin, target: nil, click: false, haptic: false)
					touches.end(origin: origin)
					glideHandler?(GlideStroke(points: capture.points, tracedLetters: capture.letters,
					                          geometry: GlideGeometry(keymap: keymap, metrics: metrics)))
				} else {
					touches.end(origin: origin)
					if let target = metrics.key(at: location) {
						commit(assisted(target, at: location, origin: origin, metrics: metrics))
					}
				}
			}, onReset: { touches.cancelIfActive(origin: origin, touchID: $0) },
			   onDisappear: { touches.cancel(origin: origin) })
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


/// Each key owns its gesture lifetime so rolling multi-finger input stays
/// independent. On iOS 18 and later the touch comes through a UIKit recognizer
/// (see KeyTouchGesture — SwiftUI's drag reports touch-down 80–100 ms late on
/// iOS 26), which announces its own cancellation. The drag remains for iOS 17
/// and the Mac; there, unlike onEnded, GestureState also resets for a cancelled
/// drag, and only this modifier observes that reset. Either way touch updates do
/// not rebuild the parent keyboard or replace the other keys' gestures.
private struct KeyboardKeyTouchLifecycle: ViewModifier {
	let space: String
	let onChanged: (CGPoint, UUID) -> Void
	let onEnded: (CGPoint, UUID) -> Void
	let onReset: @MainActor (UUID) -> Void
	let onDisappear: () -> Void
	@GestureState private var touchID: KeyboardKeyTouchState?
	@State private var lifetime = KeyboardKeyTouchLifetime()

	init(space: String, onChanged: @escaping (CGPoint, UUID) -> Void,
	     onEnded: @escaping (CGPoint, UUID) -> Void,
	     onReset: @escaping @MainActor (UUID) -> Void, onDisappear: @escaping () -> Void) {
		self.space = space
		self.onChanged = onChanged
		self.onEnded = onEnded
		self.onReset = onReset
		self.onDisappear = onDisappear
		_touchID = GestureState(wrappedValue: nil, reset: { endedID, _ in
			guard let ended = endedID else { return }
			let id = ended.id
			// A reset also occurs when a short touch never drew a SwiftUI frame,
			// so onChange is not sufficient. Let a normal onEnded finish first;
			// the token prevents an old reset from cancelling a newer same-key tap.
			Task { @MainActor in
				ended.lifetime.clear(ifMatching: id)
				onReset(id)
			}
		})
	}

	func body(content: Content) -> some View {
		#if os(iOS)
			if #available(iOS 18, *) {
				content
					.gesture(KeyTouchGesture(space: space,
					                         onBegan: { onChanged($0, lifetime.begin()) },
					                         onMoved: { onChanged($0, lifetime.begin()) },
					                         onEnded: { location in
					                         	guard let id = lifetime.end() else { return }
					                         	onEnded(location, id)
					                         },
					                         onCancelled: {
					                         	guard let id = lifetime.end() else { return }
					                         	onReset(id)
					                         }))
					.onDisappear(perform: disappear)
			} else {
				dragged(content)
			}
		#else
			dragged(content)
		#endif
	}

	private func dragged(_ content: Content) -> some View {
		content
			.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
				.updating($touchID) { _, state, _ in
					if state == nil { state = KeyboardKeyTouchState(id: lifetime.begin(), lifetime: lifetime) }
				}
				.onChanged { value in onChanged(value.location, lifetime.begin()) }
				.onEnded { value in
					guard let id = lifetime.end() else { return }
					onEnded(value.location, id)
				})
			.onDisappear(perform: disappear)
	}

	private func disappear() {
		_ = lifetime.end()
		onDisappear()
	}
}

private struct KeyboardKeyTouchState {
	let id: UUID
	let lifetime: KeyboardKeyTouchLifetime
}

@MainActor private final class KeyboardKeyTouchLifetime {
	private(set) var id: UUID?
	func begin() -> UUID {
		if let id { return id }
		let fresh = UUID()
		id = fresh
		return fresh
	}
	func end() -> UUID? {
		defer { id = nil }
		return id
	}
	func clear(ifMatching token: UUID) {
		if id == token { id = nil }
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
