//
//  KeyAlternatesGeometryTests.swift
//  KeyboardingTests
//
//  The row's placement and the choice under a finger, against a real
//  phone-width layout: rows grow away from the nearer edge, stay on the
//  keyboard, and pick by the finger's x once it has left the held key.
//

import Testing
import CoreGraphics
@testable import Keyboarding

@MainActor
@Suite("Where the alternates row sits and what the finger picks")
struct KeyAlternatesGeometryTests {
	static let metrics = KeyboardMetrics(keymap: .qwertyWithDismiss, width: 390, keyCapHeight: 54, horizontalMargin: 8)

	static func row(for letter: String, choices: [String]) -> KeyAlternatesRow {
		let key = KeyDefinition(stringLiteral: letter)
		return KeyAlternatesRow(key: key, choices: choices, slot: metrics.rect(for: key)!, hit: metrics.hitRect(for: key)!,
		                        bounds: metrics.bounds, height: metrics.keyCapHeight * 1.15)
	}

	@Test("a left-half key's row starts at the key and grows right, its cells a key wide")
	func leftKeyGrowsRight() {
		let row = Self.row(for: "E", choices: ["E", "È", "É", "Ê", "Ë"])
		let slot = Self.metrics.rect(for: "E")!
		#expect(row.frame.minX == slot.minX)
		#expect(row.cellWidth == slot.width)
		#expect(row.frame.maxY == slot.minY)
		#expect(row.selectedIndex == 0)
	}

	@Test("a right-half key's row ends at the key and grows left, its own letter moved to the key end")
	func rightKeyGrowsLeft() {
		let row = Self.row(for: "O", choices: ["O", "Ô", "Ö", "Ò"])
		let slot = Self.metrics.rect(for: "O")!
		#expect(row.frame.maxX == slot.maxX)
		#expect(row.choices == ["Ô", "Ö", "Ò", "O"])
		#expect(row.selectedIndex == 3)
		// The preselected cell is the one over the key, under the finger.
		#expect(abs(row.cellRect(at: 3).midX - slot.midX) < 0.001)
	}

	@Test("the key's own letter goes to the key end; a row without it keeps the host's order")
	func ordering() {
		#expect(KeyAlternatesRow.ordered(["A", "B", "C"], base: "A", baseLast: false) == ["A", "B", "C"])
		#expect(KeyAlternatesRow.ordered(["B", "A", "C"], base: "A", baseLast: false) == ["A", "B", "C"])
		#expect(KeyAlternatesRow.ordered(["A", "B", "C"], base: "A", baseLast: true) == ["B", "C", "A"])
		#expect(KeyAlternatesRow.ordered(["1", "2", "3"], base: "P", baseLast: true) == ["1", "2", "3"])
	}

	@Test("a row too long for its side is clamped onto the keyboard")
	func rowIsClamped() {
		let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
		let bounds = Self.metrics.bounds
		for letter in ["L", "Z", "A", "P"] {
			let row = Self.row(for: letter, choices: digits)
			#expect(row.frame.minX >= bounds.minX - 0.001)
			#expect(row.frame.maxX <= bounds.maxX + 0.001)
		}
		// Ten choices on a ten-key-wide keyboard fill it exactly, a key apiece.
		let full = Self.row(for: "L", choices: digits)
		#expect(abs(full.frame.width - bounds.width) < 0.001)
	}

	@Test("the choice follows the finger: the key itself, a cell, or off the row")
	func choiceFollowsTheFinger() {
		let row = Self.row(for: "A", choices: ["A", "À", "Á", "Â"])
		// On the held key — including its edge-reaching hit area — it's the key's letter.
		#expect(row.choice(at: CGPoint(x: row.hit.midX, y: row.hit.midY)) == "A")
		#expect(row.choice(at: CGPoint(x: row.hit.minX + 1, y: row.hit.midY)) == "A")
		// Over each cell, that cell.
		for index in row.choices.indices {
			#expect(row.choice(at: CGPoint(x: row.cellRect(at: index).midX, y: row.frame.midY)) == row.choices[index])
		}
		// Beside the key, down in its row, by x.
		#expect(row.choice(at: CGPoint(x: row.cellRect(at: 2).midX, y: row.slot.midY)) == "Á")
		// Above the row, below the key, or past its end: nothing.
		#expect(row.choice(at: CGPoint(x: row.frame.midX, y: row.frame.minY - 1)) == nil)
		#expect(row.choice(at: CGPoint(x: row.cellRect(at: 2).midX, y: row.slot.maxY + 5)) == nil)
		#expect(row.choice(at: CGPoint(x: row.frame.maxX + 5, y: row.frame.midY)) == nil)
	}

	@Test("a row without the key's own letter highlights nothing until the finger moves")
	func digitsRowStartsUnhighlighted() {
		let row = Self.row(for: "L", choices: ["1", "2", "3"])
		#expect(row.selection == "L")
		#expect(row.selectedIndex == nil)
		#expect(row.choice(at: CGPoint(x: row.cellRect(at: 0).midX, y: row.frame.midY)) == "1")
	}
}
