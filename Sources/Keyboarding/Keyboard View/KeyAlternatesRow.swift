//
//  KeyAlternatesRow.swift
//  Keyboarding
//
//  Where a held key's row of alternates sits and which choice a finger is on.
//  Pure geometry, in the keyboard's coordinate space, so the touch rules can be
//  tested without a view.
//
//  Placement follows Crosswords 7: the row starts at the held key and grows away
//  from the nearer edge — rightward from a key on the left half, leftward from
//  one on the right — then is clamped inside the keyboard. The key's own letter
//  sits at the key end either way, under the finger: first in a row growing
//  right, moved last in one growing left (the rest keep the host's order). Each choice is one
//  key wide (narrower only when the keyboard can't fit them all), and the row is
//  as tall as the key preview's balloon, sitting where that balloon sits.
//
//  Selection: while the finger stays on the held key the choice is the key's own
//  letter, so a hold-and-release types it. Off the key, the choice is whichever
//  cell the finger is beneath or beside (by x, anywhere from the row's top down
//  to the key's bottom). Anywhere else is no choice, and lifting there types
//  nothing.
//

import CoreGraphics

struct KeyAlternatesRow: Equatable {
	let key: KeyDefinition
	let choices: [String]
	/// The held key's slot, where its stem lands.
	let slot: CGRect
	/// Where the held key takes touches: the zone that still means "the key itself".
	let hit: CGRect
	/// The strip the choices are laid across.
	let frame: CGRect
	/// The choice the finger is on now, or nil when it is off the row.
	var selection: String?

	/// - Parameters:
	///   - bounds: the keyboard's keys area, which the row must stay inside.
	///   - height: the strip's height (the key preview balloon's).
	///   - gap: space between the strip and the key (none for a stemmed balloon).
	init(key: KeyDefinition, choices: [String], slot: CGRect, hit: CGRect, bounds: CGRect, height: CGFloat, gap: CGFloat = 0) {
		self.key = key
		self.slot = slot
		self.hit = hit
		let count = CGFloat(max(choices.count, 1))
		let cellWidth = min(slot.width, bounds.width / count)
		let width = cellWidth * count
		let growsLeft = slot.midX > bounds.midX
		self.choices = Self.ordered(choices, base: key.string, baseLast: growsLeft)
		let start = growsLeft ? slot.maxX - width : slot.minX
		let minX = min(max(start, bounds.minX), bounds.maxX - width)
		frame = CGRect(x: minX, y: slot.minY - gap - height, width: width, height: height)
		selection = key.string
	}

	/// The host's choices with the key's own letter (if offered) at the key end.
	static func ordered(_ choices: [String], base: String?, baseLast: Bool) -> [String] {
		guard let base, let index = choices.firstIndex(of: base) else { return choices }
		var rest = choices
		rest.remove(at: index)
		return baseLast ? rest + [base] : [base] + rest
	}

	var cellWidth: CGFloat { frame.width / CGFloat(max(choices.count, 1)) }

	func cellRect(at index: Int) -> CGRect {
		CGRect(x: frame.minX + CGFloat(index) * cellWidth, y: frame.minY, width: cellWidth, height: frame.height)
	}

	/// The index of the highlighted cell, if the current choice is in the row.
	var selectedIndex: Int? { selection.flatMap { choices.firstIndex(of: $0) } }

	/// The choice a finger at `point` is on (see the selection rules above).
	func choice(at point: CGPoint) -> String? {
		if hit.contains(point) { return key.string }
		let band = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: max(slot.maxY, frame.maxY) - frame.minY)
		guard band.contains(point), !choices.isEmpty else { return nil }
		let index = Int(((point.x - frame.minX) / cellWidth).rounded(.down))
		return choices[min(max(index, 0), choices.count - 1)]
	}
}
