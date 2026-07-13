//
//  KeyboardMetrics.swift
//  Keyboarding
//
//  Geometry for a rendered keyboard: where each key sits and which key is under
//  a touch point. Hit-testing honors the typing-assist expansion (the assist
//  key's enlarged target beats its neighbors) and clamps nearby points to the
//  nearest key, so a sliding finger never falls between keys; only moving well
//  clear of the keyboard cancels the touch.
//

import SwiftUI

struct KeyboardMetrics {
	let keymap: Keymap
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
		self.keyCapWidth = rowWidth / CGFloat(max(keymap.widestRow, 1))
		self.keyCapHeight = keyCapHeight
	}

	func leadingMargin(forRow y: Int) -> CGFloat {
		horizontalMargin + (rowWidth - CGFloat(keymap.rows[y].count) * keyCapWidth) / 2
	}

	func rect(forColumn x: Int, row y: Int) -> CGRect {
		CGRect(x: leadingMargin(forRow: y) + CGFloat(x) * keyCapWidth, y: CGFloat(y) * keyCapHeight,
		       width: keyCapWidth, height: keyCapHeight)
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
	func key(at point: CGPoint, assistKey: KeyDefinition? = nil, assistExpansion: CGFloat = 0) -> KeyDefinition? {
		guard bounds.insetBy(dx: -slop, dy: -slop).contains(point) else { return nil }
		if let assistKey, let rect = rect(for: assistKey),
		   rect.insetBy(dx: -assistExpansion / 2, dy: -assistExpansion / 2).contains(point) { return assistKey }
		let y = clamp(Int(point.y / keyCapHeight), max: keymap.rows.count - 1)
		let row = keymap.rows[y]
		let x = clamp(Int((point.x - leadingMargin(forRow: y)) / keyCapWidth), max: row.count - 1)
		return row[x]
	}

	private func clamp(_ value: Int, max limit: Int) -> Int { min(max(value, 0), limit) }
}
