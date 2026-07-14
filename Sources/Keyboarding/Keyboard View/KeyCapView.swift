//
//  KeyCapView.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/16/25.
//
//  A single keycap's static visuals. Interaction lives in KeyboardView's
//  per-key drag gestures, and press feedback (tint + preview bubble) in
//  KeyboardTouchOverlay — keycaps never re-render while typing.
//

import SwiftUI

struct KeyCapView: View {
	let definition: KeyDefinition
	@Environment(\.keyboardStyle) var kbStyle

	var body: some View {
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
