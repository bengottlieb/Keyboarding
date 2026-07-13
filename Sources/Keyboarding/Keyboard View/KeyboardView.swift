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

	// One entry per finger currently down, keyed by the key it first touched
	// (each keycap runs its own drag gesture, so rolling multi-finger typing
	// tracks independently); the value is the key now under that finger.
	@State private var touchTargets: [String: KeyDefinition] = [:]
	@State private var keyChangeHaptic = 0

	private static let space = "Keyboarding.KeyboardView"

	public init(keymap: Keymap? = nil) {
		self.keymap = keymap ?? .qwertyWithDismiss
	}

	var keyboardHorizontalMargins: CGFloat { 8 }

	var keyCapHeight: CGFloat {
		#if os(iOS)
			if UIDevice.current.orientation.isLandscape {
				44
			} else {
				54//min(keyCapWidth, 54)
			}
		#else
			54
		#endif
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
			let pressedKeys = Set(touchTargets.values)
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
						KeyCapView(definition: def, isPressed: pressedKeys.contains(def))
							.padding(currentPadding / 2)
							.frame(width: rect.width + currentPadding, height: rect.height + currentPadding)
							.font(kbStyle.keyFont.font(size: metrics.keyCapWidth * 0.5))
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

				previews(metrics: metrics)
			}
			.coordinateSpace(name: Self.space)
			.padding(.top, 12)
			.ignoresSafeArea(edges: .leading)
		}
		.frame(maxWidth: .infinity)
		.frame(height: 186)
		.background(kbStyle.background)
		.focusable()
		.onAppear { isFocused = true }
		.focused($isFocused)
		.onKeyPress { key in
			sendKey(.init(keyPress: key))
		}
		.sensoryFeedback(trigger: keyChangeHaptic) { _, _ in kbStyle.enableHaptics ? .selection : nil }
	}

	// The keyboard-space drag each keycap starts: retarget to whatever key is
	// under the finger as it moves, commit that key on touch-up. Keyed by the
	// origin key so simultaneous fingers don't fight over one entry.
	private func keyDrag(from origin: KeyDefinition, metrics: KeyboardMetrics, assistKey: KeyDefinition?, assistExpansion: CGFloat) -> some Gesture {
		DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
			.onChanged { value in
				let target = metrics.key(at: value.location, assistKey: assistKey, assistExpansion: assistExpansion)
				guard touchTargets[origin.id] != target else { return }
				if let target {
					touchTargets[origin.id] = target
					keyChangeHaptic += 1
				} else {
					touchTargets.removeValue(forKey: origin.id)
				}
			}
			.onEnded { value in
				touchTargets.removeValue(forKey: origin.id)
				if let target = metrics.key(at: value.location, assistKey: assistKey, assistExpansion: assistExpansion) {
					commit(target)
				}
			}
	}

	private func commit(_ key: KeyDefinition) {
		switch key.type {
		case .dismiss:
			#if os(iOS)
				UIView.resignAllFirstResponders()
			#endif

		default:
			_ = sendKey(key)
		}
	}

	// A preview bubble above each touched letter key (special keys don't
	// preview, matching the system keyboard).
	@ViewBuilder
	private func previews(metrics: KeyboardMetrics) -> some View {
		let width = metrics.keyCapWidth * 1.6
		let height = metrics.keyCapHeight * 1.15
		ForEach(touchTargets.keys.sorted(), id: \.self) { originID in
			if let target = touchTargets[originID], target.type == .letter, let text = target.string,
			   let rect = metrics.rect(for: target) {
				KeyPreviewBubble(text: text)
					.font(kbStyle.keyFont.font(size: metrics.keyCapWidth * 0.66))
					.frame(width: width, height: height)
					.position(x: min(max(rect.midX, metrics.bounds.minX + width / 2), metrics.bounds.maxX - width / 2),
					          y: rect.minY - height / 2 - 4)
					.zIndex(200)
					.allowsHitTesting(false)
			}
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
