//
//  KeyPreviewBubble.swift
//  Keyboarding
//
//  The system-keyboard-style popup shown above the key currently under a touch,
//  so the letter isn't hidden by the finger while it can still slide to another
//  key. Purely decorative — the touch keeps tracking beneath it.
//
//  Two shapes, chosen by `KeyboardStyle.keyPreview`:
//
//  `.stemmed` matches the original Crosswords keyboard's pop view (and the
//  system keyboard's): a wide balloon whose shoulders sweep down into a stem the
//  width of the key, ending over the keycap itself. The stem is opaque and
//  covers the cap, so the key reads as having lifted off the keyboard.
//
//  `.floating` is a detached rounded rectangle above the key, which stays put
//  and tinted underneath.
//
//  Only the outline differs — fill, shadow and letter are shared. The frame each
//  one wants differs too (stemmed spans the key, floating stops above it), and
//  that lives in KeyboardTouchOverlay, which knows the geometry.
//

import SwiftUI

struct KeyPreviewBubble: View {
	let text: String
	/// The key being previewed, in this view's own coordinate space — the stem
	/// narrows to it and ends on it. Passed in rather than assumed centered so an
	/// edge key's balloon can slide inward and stay on screen with the stem still
	/// over the key.
	let keyWidth: CGFloat
	let keyHeight: CGFloat
	let stemCenterX: CGFloat
	let balloonHeight: CGFloat
	@Environment(\.keyboardStyle) var kbStyle

	var body: some View {
		ZStack(alignment: .top) {
			shape
				// An opaque base first: the themed colors are often translucent, and a
				// see-through bubble reads as a rendering glitch — doubly so now that
				// the stem has to hide the keycap underneath it.
				.fill(.background)
				.overlay { shape.fill(kbStyle.background) }
				.overlay { shape.fill(kbStyle.keyFace) }
				.shadow(color: .black.opacity(0.25), radius: 3, y: 1)
			Text(text)
				.foregroundStyle(kbStyle.keyInk)
				.frame(height: balloonHeight)
		}
	}

	private var shape: AnyShape {
		switch kbStyle.keyPreview {
		case .stemmed:
			AnyShape(KeyPreviewShape(keyWidth: keyWidth, keyHeight: keyHeight,
			                         stemCenterX: stemCenterX, cornerRadius: kbStyle.cornerRadius * 1.5))
		case .floating:
			AnyShape(RoundedRectangle(cornerRadius: kbStyle.cornerRadius * 1.5))
		}
	}
}

/// Balloon + stem + keycap as one outline, so it fills as a single opaque shape
/// with no seam where the stem meets the key.
struct KeyPreviewShape: Shape {
	var keyWidth: CGFloat
	var keyHeight: CGFloat
	var stemCenterX: CGFloat
	var cornerRadius: CGFloat

	nonisolated func path(in rect: CGRect) -> Path {
		let radius = min(cornerRadius, keyWidth / 2)
		let half = min(keyWidth, rect.width) / 2
		let stemLeft = max(rect.minX, stemCenterX - half)
		let stemRight = min(rect.maxX, stemCenterX + half)
		let keyTop = rect.maxY - keyHeight
		// How much height the shoulders take to sweep in to the stem. Bounded by
		// the balloon so a short popup degrades to a gentle taper, never inverts.
		let neck = min(keyHeight * 0.6, max(rect.height - keyHeight, 0) * 0.5)
		let shoulderY = keyTop - neck

		var path = Path()
		path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
		path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
		path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
		                  control: CGPoint(x: rect.maxX, y: rect.minY))
		path.addLine(to: CGPoint(x: rect.maxX, y: shoulderY))
		path.addQuadCurve(to: CGPoint(x: stemRight, y: keyTop),
		                  control: CGPoint(x: rect.maxX, y: keyTop))
		path.addLine(to: CGPoint(x: stemRight, y: rect.maxY - radius))
		path.addQuadCurve(to: CGPoint(x: stemRight - radius, y: rect.maxY),
		                  control: CGPoint(x: stemRight, y: rect.maxY))
		path.addLine(to: CGPoint(x: stemLeft + radius, y: rect.maxY))
		path.addQuadCurve(to: CGPoint(x: stemLeft, y: rect.maxY - radius),
		                  control: CGPoint(x: stemLeft, y: rect.maxY))
		path.addLine(to: CGPoint(x: stemLeft, y: keyTop))
		path.addQuadCurve(to: CGPoint(x: rect.minX, y: shoulderY),
		                  control: CGPoint(x: rect.minX, y: keyTop))
		path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
		path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
		                  control: CGPoint(x: rect.minX, y: rect.minY))
		path.closeSubpath()
		return path
	}
}
