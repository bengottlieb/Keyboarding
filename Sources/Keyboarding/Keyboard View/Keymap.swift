//
//  Keymap.swift
//  
//
//  Created by Ben Gottlieb on 8/15/23.
//

import SwiftUI

// Equatable so a host rebuilding the same keymap on every render doesn't
// invalidate the keyboard — see KeyboardView's note on per-keystroke rebuilds.
public struct Keymap: Sendable, Equatable {
	public var rows: [[KeyDefinition]]
	public init(rows: [[KeyDefinition]]) {
		self.rows = rows
	}
	/// Width of the widest row in key units (a letter key is 1), which sets the
	/// unit width every row is measured in.
	public var widestRowUnits: CGFloat {
		rows.map { units(inRow: $0) }.max() ?? 0
	}

	func units(inRow row: [KeyDefinition]) -> CGFloat {
		row.reduce(0) { $0 + $1.width }
	}
}

extension Keymap {
	@MainActor public static var qwerty = Keymap(rows: [
		[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
		[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
		[ "Z", "X", "C", "V", "B", "N", "M", .init(.delete) ]
	])
	
	@MainActor public static var qwertyWithDismiss = Keymap(rows: [
		[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
		[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
		[ .init(.dismiss), "Z", "X", "C", "V", "B", "N", "M", .init(.delete) ]
	])
}
//
//extension PressedKey: KeyDefinition {
//	public var keycapImage: Image? {
//		if key == .delete { return Image(systemName: "delete.left") }
//		if key == .return { return Image(systemName: "return") }
//		if key == .tab { return Image(systemName: "arrow.right.to.line.compact") }
//		return nil
//	}
//	
//	public var pressedKey: PressedKey { self }
//}
//
//
