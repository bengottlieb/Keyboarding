//
//  KeyEdgeTouchTests.swift
//  Keyboarding
//
//  The half-key beside A and beside L belongs to those keys, as it does on the
//  system keyboard: a tap there types the letter rather than falling through.
//

import Testing
import SwiftUI
@testable import Keyboarding

@MainActor
struct KeyEdgeTouchTests {
	// iPhone-sized: 402pt wide, 8pt margins, a 386pt row of 38.6pt units.
	private let width: CGFloat = 402

	private func metrics(_ rows: [[KeyDefinition]]) -> KeyboardMetrics {
		KeyboardMetrics(keymap: Keymap(rows: rows), width: width, keyCapHeight: 54, horizontalMargin: 8)
	}

	private let qwerty: [[KeyDefinition]] = [
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L"],
	]

	@Test func endKeysOfAnInsetRowReachTheKeyboardEdges() {
		let metrics = metrics(qwerty)
		let a = metrics.hitRect(forColumn: 0, row: 1), l = metrics.hitRect(forColumn: 8, row: 1)
		#expect(a.minX == 0)
		#expect(a.maxX == metrics.rect(forColumn: 0, row: 1).maxX, "A's right edge stays its own")
		#expect(l.maxX == width)
		#expect(l.minX == metrics.rect(forColumn: 8, row: 1).minX)
		#expect(metrics.hitRect(forColumn: 4, row: 1) == metrics.rect(forColumn: 4, row: 1), "inner keys keep their slots")
	}

	@Test func aTapInTheGapBesideAOrLTypesThatLetter() {
		let metrics = metrics(qwerty)
		let y = 54 * 1.5
		let besideA = (metrics.rect(forColumn: 0, row: 1).minX) / 2
		let besideL = (metrics.rect(forColumn: 8, row: 1).maxX + width) / 2
		#expect(metrics.key(at: CGPoint(x: besideA, y: y))?.string == "A")
		#expect(metrics.key(at: CGPoint(x: besideL, y: y))?.string == "L")
	}

	@Test func aBlankSpacerAtARowsEndBelongsToTheKeyBesideIt() {
		let metrics = metrics([
			["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
			[KeyDefinition(.blank).width(1.5), "Z", "X", "C", "V", "B", "N", "M", KeyDefinition(.delete).width(1.5)],
		])
		let z = metrics.hitRect(forColumn: 1, row: 1)
		#expect(z.minX == 0)
		let overBlank = CGPoint(x: metrics.rect(forColumn: 0, row: 1).midX, y: 54 * 1.5)
		#expect(metrics.key(at: overBlank)?.string == "Z")
	}
}
