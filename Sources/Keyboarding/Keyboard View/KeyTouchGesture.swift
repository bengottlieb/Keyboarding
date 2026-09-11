//
//  KeyTouchGesture.swift
//  Keyboarding
//
//  A key's touch, taken from UIKit directly. SwiftUI's DragGesture(minimumDistance: 0)
//  reports touch-down 80–100 ms after the finger lands on iOS 26 — measured against
//  the touch's own timestamp, in a bare hosting view as much as in a host app, and
//  no better with .highPriorityGesture — while UIKit hands over touchesBegan within
//  a frame. The keyboard's whole feel rests on that first callback being immediate:
//  the click, the haptic, the press tint and the hold timer all start there, and a
//  late one reads as the key hesitating (or, on a held key, as a false "the hold
//  took"). UIGestureRecognizerRepresentable lets the recognizer live in the SwiftUI
//  gesture graph like the drag it replaces: hit-tested to the key, its location
//  converted into the keyboard's coordinate space.
//

#if os(iOS)
	import SwiftUI
	import UIKit

	@available(iOS 18, *)
	struct KeyTouchGesture: UIGestureRecognizerRepresentable {
		let space: String
		let onBegan: (CGPoint) -> Void
		let onMoved: (CGPoint) -> Void
		let onEnded: (CGPoint) -> Void
		let onCancelled: () -> Void

		func makeUIGestureRecognizer(context: Context) -> KeyTouchRecognizer { KeyTouchRecognizer() }

		func handleUIGestureRecognizerAction(_ recognizer: KeyTouchRecognizer, context: Context) {
			switch recognizer.state {
			case .began: onBegan(context.converter.location(in: .named(space)))
			case .changed: onMoved(context.converter.location(in: .named(space)))
			case .ended: onEnded(context.converter.location(in: .named(space)))
			case .cancelled, .failed: onCancelled()
			default: break
			}
		}
	}

	/// Begins on the first touch and follows only that one: a second finger on the
	/// same key is ignored (a slip, not a chord), while fingers on other keys belong
	/// to those keys' recognizers — rolling multi-finger typing tracks per key.
	final class KeyTouchRecognizer: UIGestureRecognizer {
		private var tracked: UITouch?

		override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
			for touch in touches {
				if tracked == nil { tracked = touch } else if touch !== tracked { ignore(touch, for: event) }
			}
			if state == .possible, tracked != nil { state = .began }
		}

		override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
			guard let tracked, touches.contains(tracked) else { return }
			state = .changed
		}

		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
			guard let tracked, touches.contains(tracked) else { return }
			state = .ended
		}

		override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
			guard let tracked, touches.contains(tracked) else { return }
			state = .cancelled
		}

		override func reset() {
			tracked = nil
		}
	}
#endif
