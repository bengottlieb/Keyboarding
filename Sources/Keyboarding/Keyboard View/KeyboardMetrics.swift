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
//  Split (see KeyboardSplit), each row is two halves: the left one starts at
//  the leading margin, the right one ends at the trailing margin, and the
//  divider between them is nobody's. Keys keep the split's preferred width
//  unless the room beside the divider forces them narrower.
//
//  Typing assist is NOT part of this hit test — it applies once, at commit
//  (see `assisted(_:at:assistKey:expansion:)`), so the key under the finger is
//  always the key the preview bubble shows.
//

import SwiftUI

struct KeyboardMetrics {
	let keymap: Keymap
	/// The rows as laid out: the keymap's, or each row's halves joined with the
	/// right half starting at `splitIndex` when split.
	let rows: [[KeyDefinition]]
	private let splitIndex: [Int]
	/// The x-range the halves keep clear, when split.
	let divider: ClosedRange<CGFloat>?
	/// Width of one key unit — the width of a letter key.
	let keyCapWidth: CGFloat
	/// The inset of each key's face within its slot: the gap between keys.
	let faceInset: CGFloat
	let keyCapHeight: CGFloat
	let horizontalMargin: CGFloat
	let rowWidth: CGFloat

	// How far outside the keys a touch keeps tracking before it cancels.
	var slop: CGFloat { keyCapHeight }

	init(keymap: Keymap, width: CGFloat, keyCapHeight: CGFloat, horizontalMargin: CGFloat, split: KeyboardSplit? = nil) {
		self.keymap = keymap
		self.horizontalMargin = horizontalMargin
		self.rowWidth = width - horizontalMargin * 2
		self.keyCapHeight = keyCapHeight
		if let split {
			rows = split.rows.map { $0.left + $0.right }
			splitIndex = split.rows.map { $0.left.count }
			divider = split.divider
			let room = max(rowWidth - (split.divider.upperBound - split.divider.lowerBound), 0) / 2
			keyCapWidth = min(split.keyCapWidth, room / max(split.widestHalfUnits, 1))
			faceInset = split.faceInset
		} else {
			rows = keymap.rows
			splitIndex = keymap.rows.map(\.count)
			divider = nil
			keyCapWidth = rowWidth / max(keymap.widestRowUnits, 1)
			faceInset = Self.continuousFaceInset
		}
	}

	/// A continuous keyboard's gap between keys, the system keyboard's.
	static let continuousFaceInset: CGFloat = 2

	static func units(of keys: some Sequence<KeyDefinition>) -> CGFloat {
		keys.reduce(0) { $0 + $1.width }
	}

	func leadingMargin(forRow y: Int) -> CGFloat {
		guard divider == nil else { return horizontalMargin }
		return horizontalMargin + (rowWidth - Self.units(of: rows[y]) * keyCapWidth) / 2
	}

	/// Where the right half of a split row starts, so it ends at the trailing margin.
	private func rightHalfStart(forRow y: Int) -> CGFloat {
		horizontalMargin + rowWidth - Self.units(of: rows[y][splitIndex[y]...]) * keyCapWidth
	}

	func rect(forColumn x: Int, row y: Int) -> CGRect {
		let keys = rows[y]
		let start = splitIndex[y]
		let minX = x < start
			? leadingMargin(forRow: y) + Self.units(of: keys[..<x]) * keyCapWidth
			: rightHalfStart(forRow: y) + Self.units(of: keys[start..<x]) * keyCapWidth
		return CGRect(x: minX, y: CGFloat(y) * keyCapHeight, width: keys[x].width * keyCapWidth, height: keyCapHeight)
	}

	func rect(for key: KeyDefinition) -> CGRect? {
		for (y, row) in rows.enumerated() {
			if let x = row.firstIndex(of: key) { return rect(forColumn: x, row: y) }
		}
		return nil
	}

	var bounds: CGRect {
		CGRect(x: horizontalMargin, y: 0, width: rowWidth, height: CGFloat(rows.count) * keyCapHeight)
	}

	/// The key under a touch, or nil once the finger has moved too far away.
	func key(at point: CGPoint) -> KeyDefinition? {
		guard bounds.insetBy(dx: -slop, dy: -slop).contains(point) else { return nil }
		let y = clamp(Int(point.y / keyCapHeight), max: rows.count - 1)
		let row = rows[y]
		// A split row is two runs; the divider's middle decides which one the
		// finger is over, so a point in the gap clamps to the nearer half's edge.
		let keys: ArraySlice<KeyDefinition>
		let start: CGFloat
		if let divider, point.x >= (divider.lowerBound + divider.upperBound) / 2 {
			keys = row[splitIndex[y]...]
			start = rightHalfStart(forRow: y)
		} else {
			keys = row[..<splitIndex[y]]
			start = leadingMargin(forRow: y)
		}
		// Walk the run in units so a point left of the first key lands on it and one
		// past the last key lands on that — the same clamping a uniform row got.
		var remaining = (point.x - start) / keyCapWidth
		for key in keys {
			if remaining < key.width { return key }
			remaining -= key.width
		}
		return keys.last ?? row.last
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
