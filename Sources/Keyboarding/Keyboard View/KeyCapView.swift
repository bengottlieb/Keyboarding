//
//  KeyCapView.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/16/25.
//
//  A single keycap's static visuals. Interaction lives in KeyboardView's
//  per-key drag gestures, and press feedback (tint + preview bubble) in
//  KeyboardTouchOverlay — so a touch never re-renders a keycap.
//
//  `keyboardAvailableLetters` is the exception: its provider is called here, in
//  the cap's own body, so a host that recomputes the set per keystroke
//  re-renders every cap — which is the point, the dimming has to track what was
//  just typed — while the keyboard around them (and its gestures) stands still.
//

import SwiftUI

struct KeyCapView: View {
	let definition: KeyDefinition
	@Environment(\.keyboardStyle) var kbStyle
	@Environment(\.keyboardAvailableLetters) var availableLetters

	var body: some View {
		if definition.type == .blank {
			// A spacer holding a row's shoulder open: no face, no glyph, nothing to read.
			Color.clear
		} else {
			keyCap
		}
	}

	private var keyCap: some View {
		ZStack {
			label
				.offset(y: 2)
				.opacity(0.25)
			label
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(.bottom, 10)
		.padding(.top, 2)
		.background {
			RoundedRectangle(cornerRadius: kbStyle.cornerRadius)
				.fill(kbStyle.keyFace)
				.padding(2)
		}
		.foregroundStyle(ink)
		// The whole cap, face included, so an unavailable key recedes instead of
		// reading as a normal key someone forgot to ink in.
		.opacity(isUnavailable ? kbStyle.unavailableKeyOpacity : 1)
		// A hint, not `.isNotEnabled`: the key still types, and the trait would
		// tell VoiceOver otherwise.
		.accessibilityHint(isUnavailable ? Text("Unavailable") : Text(""))
	}

	private var isUnavailable: Bool {
		guard definition.type == .letter, let availableLetters else { return false }
		return definition.isUnavailable(given: availableLetters())
	}

	private var ink: Color { definition.string == nil ? kbStyle.specialInk : kbStyle.keyInk }

	@ViewBuilder private var label: some View {
		if let text = definition.string {
			Text(text)
		} else if let image = definition.type.imageName {
			Image(systemName: image)
		}
	}
}
