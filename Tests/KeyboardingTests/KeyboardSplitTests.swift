//
//  KeyboardSplitTests.swift
//  Keyboarding
//
//  A split keyboard is the system's on a partly opened foldable: two halves
//  at the outer edges with the same letter columns on each, the middle letter
//  of an odd row on both sides, and nothing on the fold.
//

import Testing
import SwiftUI
@testable import Keyboarding

@MainActor
struct KeyboardSplitTests {
	private let keymap = Keymap(rows: [
		[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
		[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
		[ KeyDefinition(.dismiss).width(0.75), KeyDefinition(.pencil).width(0.75), "Z", "X", "C", "V", "B", "N", "M", KeyDefinition(.delete).width(1.5) ]
	])

	private func split(width: CGFloat, dividerWidth: CGFloat = 0) -> KeyboardSplit {
		let middle = width / 2
		return KeyboardSplit(keymap: keymap, divider: (middle - dividerWidth / 2)...(middle + dividerWidth / 2), keyCapWidth: 46, faceInset: 4)
	}

	private func metrics(width: CGFloat, dividerWidth: CGFloat = 0) -> KeyboardMetrics {
		KeyboardMetrics(keymap: keymap, width: width, keyCapHeight: 54, horizontalMargin: 8,
		                split: split(width: width, dividerWidth: dividerWidth))
	}

	@Test func evenRowsSplitDownTheMiddle() {
		let rows = split(width: 951).rows
		#expect(rows[0].left == ["Q", "W", "E", "R", "T"])
		#expect(rows[0].right == ["Y", "U", "I", "O", "P"])
	}

	/// The system keyboard puts G and V on both halves so each keeps five columns.
	@Test func oddRowsPutTheMiddleLetterOnBothSides() {
		let rows = split(width: 951).rows
		#expect(rows[1].left == ["A", "S", "D", "F", "G"])
		#expect(rows[1].right.map(\.string) == ["G", "H", "J", "K", "L"])
		#expect(rows[1].right[0].isSplitTwin)
		#expect(rows[1].right[0] != "G", "the copy is its own key to the touch model")
		#expect(rows[1].right[0].id != KeyDefinition("G").id)
	}

	@Test func functionKeysStayOnTheSideTheyFlank() {
		let bottom = split(width: 951).rows[2]
		#expect(bottom.left.map(\.type) == [.dismiss, .pencil, .letter, .letter, .letter, .letter])
		#expect(bottom.left.suffix(4) == ["Z", "X", "C", "V"])
		#expect(bottom.right.map(\.string) == ["V", "B", "N", "M", nil])
		#expect(bottom.right.last?.type == .delete)
	}

	@Test func halvesHugTheOuterEdgesAndKeepTheFoldClear() throws {
		let m = metrics(width: 951, dividerWidth: 40)
		#expect(m.keyCapWidth == 46, "room to spare, so the keys keep the split's width")
		let q = try #require(m.rect(for: "Q"))
		let p = try #require(m.rect(for: "P"))
		#expect(q.minX == 8)
		#expect(abs(p.maxX - (951 - 8)) < 0.01)
		for row in m.rows.indices {
			for column in m.rows[row].indices {
				let rect = m.rect(forColumn: column, row: row)
				#expect(rect.maxX <= 951 / 2 - 20 || rect.minX >= 951 / 2 + 20, "\\(m.rows[row][column].id) sits on the fold")
			}
		}
	}

	@Test func aNarrowDisplayShrinksTheKeysToFitBesideTheFold() {
		// 5.5 units a half, 8pt margins, a 40pt fold: (500 - 16 - 40) / 2 / 5.5.
		let m = metrics(width: 500, dividerWidth: 40)
		#expect(abs(m.keyCapWidth - 444 / 2 / 5.5) < 0.01)
	}

	@Test func eachCopyOfASharedLetterHasItsOwnPlace() throws {
		let m = metrics(width: 951)
		let left = try #require(m.rect(for: "G"))
		let right = try #require(m.rect(for: KeyDefinition("G").splitTwin()))
		#expect(left.maxX < 951 / 2)
		#expect(right.minX > 951 / 2)
	}

	/// A finger in the gap is over whichever half is nearer, on that half's edge key.
	@Test func touchesInTheGapClampToTheNearerHalf() {
		let m = metrics(width: 951)
		let y = 54 * 1.5
		#expect(m.key(at: CGPoint(x: 951 / 2 - 30, y: y)) == "G")
		#expect(m.key(at: CGPoint(x: 951 / 2 + 30, y: y)) == KeyDefinition("G").splitTwin())
		#expect(m.key(at: CGPoint(x: 8 + 46 * 2.5, y: y)) == "D")
	}

	/// The halves get more room between their keys than a continuous keyboard.
	@Test func splitKeysKeepTheirOwnGap() {
		#expect(metrics(width: 951).faceInset == 4)
		#expect(KeyboardMetrics(keymap: keymap, width: 402, keyCapHeight: 54, horizontalMargin: 8).faceInset == 2)
	}

	@Test func aContinuousKeyboardIsUnchanged() throws {
		let m = KeyboardMetrics(keymap: keymap, width: 402, keyCapHeight: 54, horizontalMargin: 8)
		#expect(m.divider == nil)
		#expect(m.rows == keymap.rows)
		#expect(m.keyCapWidth == 386.0 / 10)
	}
}
