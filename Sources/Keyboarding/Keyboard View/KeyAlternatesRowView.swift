//
//  KeyAlternatesRowView.swift
//  Keyboarding
//
//  A held key's row of alternates, drawn as a widened key preview: the same
//  balloon (stemmed onto the held key, or floating above it, per
//  `KeyboardStyle.keyPreview`) with one cell per choice and the current choice
//  highlighted, the way Crosswords 7 lit it — tint behind, white letter.
//  Decorative only; the touch that opened it keeps tracking beneath.
//

import SwiftUI

struct KeyAlternatesRowView: View {
	let row: KeyAlternatesRow
	@Environment(\.keyboardStyle) private var kbStyle

	// Matches the key preview's stem: the keycap face is inset this much in its slot.
	private let capInset: CGFloat = 2

	var body: some View {
		let stemmed = kbStyle.keyPreview == .stemmed
		let stem = stemmed ? CGSize(width: row.slot.width - capInset * 2, height: row.slot.height - capInset) : .zero
		let frame = CGRect(x: row.frame.minX, y: row.frame.minY, width: row.frame.width, height: row.frame.height + stem.height)
		ZStack(alignment: .topLeading) {
			KeyPreviewBubble(text: "", keyWidth: stemmed ? stem.width : row.frame.width, keyHeight: stem.height,
			                 stemCenterX: row.slot.midX - frame.minX, balloonHeight: row.frame.height)
			HStack(spacing: 0) {
				ForEach(row.choices.indices, id: \.self) { index in
					cell(row.choices[index], selected: index == row.selectedIndex)
				}
			}
			.frame(height: row.frame.height)
		}
		.frame(width: frame.width, height: frame.height)
		.position(x: frame.midX, y: frame.midY)
	}

	private func cell(_ choice: String, selected: Bool) -> some View {
		Text(choice)
			.font(kbStyle.keyFont.font(size: min(row.cellWidth, row.frame.height) * 0.55))
			.foregroundStyle(selected ? Color.white : kbStyle.keyInk)
			.frame(width: row.cellWidth, height: row.frame.height)
			.background {
				if selected {
					RoundedRectangle(cornerRadius: kbStyle.cornerRadius)
						.fill(Color.accentColor)
						.padding(capInset)
				}
			}
			.accessibilityIdentifier("Keyboarding.keyAlternate.\(choice)")
	}
}
