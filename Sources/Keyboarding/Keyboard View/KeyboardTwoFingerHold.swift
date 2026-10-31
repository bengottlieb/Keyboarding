//
//  KeyboardTwoFingerHold.swift
//  Keyboarding
//
//  A block a host can run on two fingers held still on the keyboard for half
//  a second (a font panel for the keys, say). It is the keyboard's own
//  recognizer, beside the keys' touches, so that it can take the keys over:
//  while two fingers are down no key starts its hold, and when the hold lands
//  every key still pressed ends without typing (KeyboardTouchModel+TwoFingers).
//  A pinch or a two-finger slide moves past the allowance and fails it, and so
//  does a finger lifting first — rolling typing types exactly as before.
//  UIKit's, since SwiftUI has no multi-finger long press (iOS 18; the Mac and
//  iOS 17 install nothing).
//

import SwiftUI
#if os(iOS)
	import UIKit
#endif

public struct KeyboardTwoFingerHold: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let handle: @MainActor () -> Void

	@MainActor public func callAsFunction() { handle() }

	// Identified by creation site only (like KeyLongPressHandler), so a block
	// rebuilt on every render of its host leaves the environment stable.
	public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.line == rhs.line && lhs.file == rhs.file }

	public init(_ handle: @MainActor @escaping () -> Void, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.handle = handle
	}
}

extension EnvironmentValues {
	/// The host's block for a two-finger hold on the keyboard; nil installs none.
	@Entry public var keyboardTwoFingerHold: KeyboardTwoFingerHold? = nil
}

struct KeyboardTwoFingerHoldModifier: ViewModifier {
	let hold: KeyboardTwoFingerHold?
	let touches: KeyboardTouchModel

	func body(content: Content) -> some View {
		#if os(iOS)
			if #available(iOS 18, *), let hold {
				content.gesture(KeyboardTwoFingerHoldGesture(touches: touches, hold: hold))
			} else {
				content
			}
		#else
			content
		#endif
	}
}

#if os(iOS)
	@available(iOS 18, *)
	private struct KeyboardTwoFingerHoldGesture: UIGestureRecognizerRepresentable {
		let touches: KeyboardTouchModel
		let hold: KeyboardTwoFingerHold

		func makeCoordinator(converter: CoordinateSpaceConverter) -> KeyboardTwoFingerHoldDelegate { KeyboardTwoFingerHoldDelegate() }

		func makeUIGestureRecognizer(context: Context) -> KeyboardTwoFingerHoldRecognizer {
			let recognizer = KeyboardTwoFingerHoldRecognizer()
			recognizer.delegate = context.coordinator
			recognizer.onTwoFingers = { [touches] in touches.suspendHolds($0) }
			return recognizer
		}

		func handleUIGestureRecognizerAction(_ recognizer: KeyboardTwoFingerHoldRecognizer, context: Context) {
			guard recognizer.state == .began else { return }
			touches.spendActiveTouches()
			hold()
		}
	}

	/// Beside, never instead of, the keys' own touches.
	final class KeyboardTwoFingerHoldDelegate: NSObject, UIGestureRecognizerDelegate {
		func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
		                       shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
	}

	/// A two-touch long press that also says when two touches are down.
	final class KeyboardTwoFingerHoldRecognizer: UILongPressGestureRecognizer {
		var onTwoFingers: @MainActor (Bool) -> Void = { _ in }
		private var touchCount = 0 { didSet { if (touchCount >= 2) != (oldValue >= 2) { onTwoFingers(touchCount >= 2) } } }

		init() {
			super.init(target: nil, action: nil)
			numberOfTouchesRequired = 2
			minimumPressDuration = 0.5
			allowableMovement = 12
			// The keys end their own presses when the hold lands; the view's other
			// touches are none of this recognizer's business.
			cancelsTouchesInView = false
		}

		override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
			touchCount += touches.count
			super.touchesBegan(touches, with: event)
		}

		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
			touchCount = max(0, touchCount - touches.count)
			super.touchesEnded(touches, with: event)
		}

		override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
			touchCount = max(0, touchCount - touches.count)
			super.touchesCancelled(touches, with: event)
		}

		override func reset() {
			touchCount = 0
			super.reset()
		}
	}
#endif
