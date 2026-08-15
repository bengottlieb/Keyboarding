//
//  KeyboardMetrics.swift
//  Keyboarding
//
//  Geometry for a rendered keyboard: where each key sits and which key is under
//  a touch point. Rows are laid out in key-width units (a letter is 1, a
//  shoulder key more), so the letters flanked by function keys stay on the same
//  columns as the system keyboard. Points near the keys clamp to the nearest
//  one, so a sliding finger never falls between keys; only moving well clear of
//  the keyboard cancels the touch.
//
//  Typing assist is NOT part of this hit test — it applies once, at commit
//  (see `assisted(_:at:assistKey:expansion:)`), so the key under the finger is
//  always the key the preview bubble shows.
//

import SwiftUI

struct KeyboardMetrics {
	let keymap: Keymap
	/// Width of one key unit — the width of a letter key.
	let keyCapWidth: CGFloat
	let keyCapHeight: CGFloat
	let horizontalMargin: CGFloat
	let rowWidth: CGFloat

	// How far outside the keys a touch keeps tracking before it cancels.
	var slop: CGFloat { keyCapHeight }

	init(keymap: Keymap, width: CGFloat, keyCapHeight: CGFloat, horizontalMargin: CGFloat) {
		self.keymap = keymap
		self.horizontalMargin = horizontalMargin
		self.rowWidth = width - horizontalMargin * 2
		self.keyCapWidth = rowWidth / max(keymap.widestRowUnits, 1)
		self.keyCapHeight = keyCapHeight
	}

	func leadingMargin(forRow y: Int) -> CGFloat {
		horizontalMargin + (rowWidth - keymap.units(inRow: keymap.rows[y]) * keyCapWidth) / 2
	}

	func rect(forColumn x: Int, row y: Int) -> CGRect {
		let keys = keymap.rows[y]
		let unitsBefore = keymap.units(inRow: Array(keys.prefix(x)))
		return CGRect(x: leadingMargin(forRow: y) + unitsBefore * keyCapWidth, y: CGFloat(y) * keyCapHeight,
		              width: keys[x].width * keyCapWidth, height: keyCapHeight)
	}

	func rect(for key: KeyDefinition) -> CGRect? {
		for (y, row) in keymap.rows.enumerated() {
			if let x = row.firstIndex(of: key) { return rect(forColumn: x, row: y) }
		}
		return nil
	}

	var bounds: CGRect {
		CGRect(x: horizontalMargin, y: 0, width: rowWidth, height: CGFloat(keymap.rows.count) * keyCapHeight)
	}

	/// The key under a touch, or nil once the finger has moved too far away.
	func key(at point: CGPoint) -> KeyDefinition? {
		guard bounds.insetBy(dx: -slop, dy: -slop).contains(point) else { return nil }
		let y = clamp(Int(point.y / keyCapHeight), max: keymap.rows.count - 1)
		let row = keymap.rows[y]
		// Walk the row in units so a point left of the first key lands on it and one
		// past the last key lands on that — the same clamping a uniform row got.
		var remaining = (point.x - leadingMargin(forRow: y)) / keyCapWidth
		for key in row {
			if remaining < key.width { return key }
			remaining -= key.width
		}
		return row.last
	}

	/// Typing assist, applied at commit only: swap a near-miss for the expected
	/// key when the touch landed within `expansion` of it. Callers gate this on
	/// the press qualifying (see `KeyboardTouchModel.allowsAssist`), so a
	/// deliberate press always types the key it landed on.
	func assisted(_ target: KeyDefinition, at point: CGPoint, assistKey: KeyDefinition, expansion: CGFloat) -> KeyDefinition {
		guard target != assistKey, let rect = rect(for: assistKey),
		      rect.insetBy(dx: -expansion / 2, dy: -expansion / 2).contains(point) else { return target }
		return assistKey
	}

	private func clamp(_ value: Int, max limit: Int) -> Int { min(max(value, 0), limit) }
}
