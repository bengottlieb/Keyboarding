//
//  KeyCapView.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/16/25.
//
//  A single keycap's visuals. Interaction lives in KeyboardView, which tracks
//  each touch across the whole keyboard (iOS-style: preview on touch-down,
//  slide to retarget, commit on touch-up) and passes the pressed state down.
//

import SwiftUI

struct KeyCapView: View {
	let definition: KeyDefinition
	var isPressed = false
	@Environment(\.keyboardStyle) var kbStyle

	var body: some View {
		ZStack {
			label
				.offset(y: isPressed ? 0 : 2)
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
		.scaleEffect(isPressed ? 0.9 : 1)
		.foregroundStyle(ink.opacity(isPressed ? 0.7 : 1))
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
