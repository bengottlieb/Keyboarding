//
//  KeyboardTouchModel+Alternates.swift
//  Keyboarding
//
//  A held letter key's row of alternates, as touch state: opened by the hold
//  (which spends the touch, so the key itself never commits), moved by the same
//  finger, and closed by its lift — which yields the choice to type, or nil to
//  type nothing. Cancelling the touch drops the row with nothing typed (see
//  `cancel(origin:)`). Like the preview, only the overlay reads the rows, so a
//  finger sliding along one redraws the row alone.
//

import CoreGraphics

extension KeyboardTouchModel {
	/// Open a held key's row; the caller's long-press block then spends the touch.
	func openAlternates(_ row: KeyAlternatesRow, origin: KeyDefinition) {
		alternateRows[origin.id] = row
	}

	func hasAlternates(origin: KeyDefinition) -> Bool { alternateRows[origin.id] != nil }

	/// Whether any row is open — the rest of the keyboard dims while one is.
	var isShowingAlternates: Bool { !alternateRows.isEmpty }

	/// Follow the finger along the row. Landing on a different choice plays the
	/// selection haptic (when `haptic`), straight from this touch callback like a
	/// key's own — never from a render. Moving off the row is silent.
	func moveAlternates(origin: KeyDefinition, to point: CGPoint, haptic: Bool = false) {
		guard var row = alternateRows[origin.id] else { return }
		let choice = row.choice(at: point)
		guard choice != row.selection else { return }
		row.selection = choice
		alternateRows[origin.id] = row
		if haptic, choice != nil { alternateHaptic() }
	}

	/// Close the row as the finger lifts at `point`: the choice under it, or nil
	/// when it lifted off the row (or no row was open).
	func finishAlternates(origin: KeyDefinition, at point: CGPoint) -> String? {
		alternateRows.removeValue(forKey: origin.id)?.choice(at: point)
	}
}
