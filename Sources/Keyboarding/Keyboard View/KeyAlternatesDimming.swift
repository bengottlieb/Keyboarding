//
//  KeyAlternatesDimming.swift
//  Keyboarding
//
//  While a held key's row of alternates is open the rest of the keyboard dims,
//  as Crosswords 7's did: a 30% scrim fading in over 0.2 s (at once under
//  Reduce Motion), gone the moment the row closes on release or cancel. Its own
//  view, reading the touch model, so opening a row redraws the scrim alone and
//  never the keycaps.
//

import SwiftUI

struct KeyAlternatesDimming: View {
	let touches: KeyboardTouchModel
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	static let opacity: Double = 0.3
	static let fadeIn: Double = 0.2

	var body: some View {
		let dimmed = touches.isShowingAlternates
		Rectangle()
			.fill(Color.black)
			.opacity(dimmed ? Self.opacity : 0)
			// Fades in only: closing the row restores the keys with the finger's lift.
			.animation(dimmed && !reduceMotion ? .easeOut(duration: Self.fadeIn) : nil, value: dimmed)
			.allowsHitTesting(false)
			.accessibilityHidden(true)
	}
}
