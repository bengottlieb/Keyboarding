//
//  KeyPreviewBubble.swift
//  Keyboarding
//
//  The system-keyboard-style popup shown above the key currently under a touch,
//  so the letter isn't hidden by the finger while it can still slide to another
//  key. Purely decorative — the touch keeps tracking beneath it.
//

import SwiftUI

struct KeyPreviewBubble: View {
	let text: String
	@Environment(\.keyboardStyle) var kbStyle

	var body: some View {
		ZStack {
			shape
				// An opaque base first: the themed colors are often translucent, and a
				// see-through bubble reads as a rendering glitch.
				.fill(.background)
				.overlay { shape.fill(kbStyle.background) }
				.overlay { shape.fill(kbStyle.keyFace) }
				.shadow(color: .black.opacity(0.25), radius: 3, y: 1)
			Text(text)
				.foregroundStyle(kbStyle.keyInk)
		}
	}

	private var shape: RoundedRectangle {
		RoundedRectangle(cornerRadius: kbStyle.cornerRadius * 1.5)
	}
}
