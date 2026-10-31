//
//  KeyboardFont+Scale.swift
//  Keyboarding
//
//  A typed character's size under the font's scale: the keyboard's own size
//  for it (from the key's geometry) times `scale`, except that a scale above
//  1 grows it only as far as the box it is drawn in still holds the glyph —
//  the cap's face, the preview's balloon, an alternate's cell. A landscape
//  phone's balloon is shorter than its key is wide, so there the preview may
//  not grow at all. A scale below 1 always applies, and at 1 nothing changes.
//  The rule cannot see the face, so each of those texts also shrinks itself
//  (`minimumScaleFactor`) when a wide glyph — a bold serif W — still would not
//  fit across its box.
//

import SwiftUI

public extension KeyboardFont {
	/// The size a glyph the keyboard draws at `base` takes in `box`.
	func size(base: CGFloat, fitting box: CGSize) -> CGFloat {
		min(base * scale, max(base, Self.largestFitting(box)))
	}

	/// The face at `size(base:fitting:)`.
	func font(base: CGFloat, fitting box: CGSize) -> Font {
		font(size: size(base: base, fitting: box))
	}

	/// The largest size whose glyph — a wide capital, or one with a tail —
	/// still sits inside `box` with room around it.
	static func largestFitting(_ box: CGSize) -> CGFloat {
		max(0, min(box.width * 0.85, box.height * 0.8))
	}
}
