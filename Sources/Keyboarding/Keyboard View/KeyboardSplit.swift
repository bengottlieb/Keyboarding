//
//  KeyboardSplit.swift
//  Keyboarding
//
//  A keymap cut into two halves that hug the outer edges of a display divided
//  down the middle — the way the system keyboard splits on a partly opened
//  foldable, so each thumb has its half and nothing sits on the fold. Both
//  halves keep the same number of letter columns: a row with an odd count of
//  letters puts its middle letter on both sides (G and V on QWERTY), as the
//  system keyboard does, and the function keys stay on the side they flank.
//

import SwiftUI

/// Whether the keyboard splits around a display's fold.
public enum KeyboardSplitBehavior: Sendable, Equatable {
	/// Split around a fold that runs down through the keyboard — a partly
	/// opened foldable — and lay out continuously on every other display.
	case automatic
	/// Two halves at the outer edges whatever the display.
	case always
	/// One continuous keyboard whatever the display.
	case never
}

public extension EnvironmentValues {
	@Entry var keyboardSplit: KeyboardSplitBehavior = .automatic
}

struct KeyboardSplit: Equatable, Sendable {
	struct Row: Equatable, Sendable {
		let left: [KeyDefinition]
		let right: [KeyDefinition]

		/// Cut a row so both halves hold the same number of letter columns.
		init(_ row: [KeyDefinition]) {
			let letters = row.indices.filter { row[$0].type == .letter }
			guard let first = letters.first, let last = letters.last else {
				left = row
				right = []
				return
			}
			let half = (letters.count + 1) / 2
			let leftLetters = letters.prefix(half)
			let rightLetters = letters.suffix(half)
			left = Array(row[..<first]) + leftLetters.map { row[$0] }
			// A letter on both sides is two keys to the touch model.
			right = rightLetters.map { leftLetters.contains($0) ? row[$0].splitTwin() : row[$0] } + Array(row[(last + 1)...])
		}
	}

	let rows: [Row]
	/// The x-range the halves keep clear, in the keyboard's coordinates.
	let divider: ClosedRange<CGFloat>
	/// The key width the halves prefer; the room beside the divider caps it.
	let keyCapWidth: CGFloat
	/// The inset of each face within its slot: the gap between the keys.
	let faceInset: CGFloat

	init(keymap: Keymap, divider: ClosedRange<CGFloat>, keyCapWidth: CGFloat, faceInset: CGFloat) {
		rows = keymap.rows.map(Row.init)
		self.divider = divider
		self.keyCapWidth = keyCapWidth
		self.faceInset = faceInset
	}

	/// Width of the widest half in key units.
	var widestHalfUnits: CGFloat {
		rows.map { max(KeyboardMetrics.units(of: $0.left), KeyboardMetrics.units(of: $0.right)) }.max() ?? 0
	}
}
