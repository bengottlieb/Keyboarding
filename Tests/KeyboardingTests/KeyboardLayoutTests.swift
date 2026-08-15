//
//  KeyboardLayoutTests.swift
//  Keyboarding
//
//  Rows are measured in key-width units, not key counts. The point of that is a
//  bottom row whose letters sit on the same columns as the system keyboard no
//  matter how many function keys flank them — so these pin the columns, not just
//  the arithmetic.
//

import Testing
import SwiftUI
@testable import Keyboarding

@MainActor
struct KeyboardLayoutTests {
	/// The bottom row every puzzle keyboard uses: 1.5 units of function keys on
	/// each side of Z–M, exactly like shift and delete on the system keyboard.
	private func shoulderedKeymap(leading: [KeyDefinition]) -> Keymap {
		let width = 1.5 / CGFloat(leading.count)
		var bottom = leading.map { $0.width(width) }
		bottom += ["Z", "X", "C", "V", "B", "N", "M"]
		bottom.append(KeyDefinition(.delete).width(1.5))
		return Keymap(rows: [
			[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
			[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
			bottom
		])
	}

	private func metrics(_ keymap: Keymap) -> KeyboardMetrics {
		// iPhone-sized: 402pt wide, 8pt margins → a 386pt row of 38.6pt units.
		KeyboardMetrics(keymap: keymap, width: 402, keyCapHeight: 54, horizontalMargin: 8)
	}

	@Test func widestRowIsMeasuredInUnitsNotKeys() throws {
		// Bottom row holds 10 keys' worth of width in 10 keys, but only because the
		// shoulders are wide — a key count would read 10 either way and hide the bug.
		let keymap = shoulderedKeymap(leading: [.init(.dismiss), .init(.pencil)])
		#expect(keymap.widestRowUnits == 10)
		#expect(metrics(keymap).keyCapWidth == 386.0 / 10)
	}

	/// The whole point of the change: Z's centre lands on S's centre, where every
	/// iOS keyboard puts it. Before shoulders it sat half a key to the right.
	@Test func bottomRowLettersLineUpWithTheRowAbove() throws {
		let m = metrics(shoulderedKeymap(leading: [.init(.dismiss), .init(.pencil)]))
		let z = try #require(m.rect(for: "Z"))
		let s = try #require(m.rect(for: "S"))
		#expect(abs(z.midX - s.midX) < 0.01)
	}

	/// A host with no function keys on the left holds the shoulder with a spacer,
	/// so its letters land on the same columns as a host that has three.
	@Test func lettersHoldTheirColumnsWhateverFillsTheShoulder() throws {
		let spacerOnly = metrics(shoulderedKeymap(leading: [.init(.blank)]))
		let three = metrics(shoulderedKeymap(leading: [.init(.tab), .init(.dismiss), .init(.pencil)]))
		for letter: KeyDefinition in ["Z", "X", "C", "V", "B", "N", "M"] {
			let a = try #require(spacerOnly.rect(for: letter))
			let b = try #require(three.rect(for: letter))
			#expect(abs(a.minX - b.minX) < 0.01)
			#expect(a.width == b.width)
		}
	}

	@Test func hitTestingWalksVariableWidths() throws {
		let m = metrics(shoulderedKeymap(leading: [.init(.dismiss), .init(.pencil)]))
		let bottomY = m.keyCapHeight * 2.5
		for letter: KeyDefinition in ["Z", "C", "M"] {
			let rect = try #require(m.rect(for: letter))
			#expect(m.key(at: CGPoint(x: rect.midX, y: bottomY)) == letter)
		}
		let dismiss = try #require(m.rect(for: .init(.dismiss)))
		#expect(m.key(at: CGPoint(x: dismiss.midX, y: bottomY)) == KeyDefinition(.dismiss))
	}

	/// A finger drifting past either end of a row keeps the edge key rather than
	/// falling into a gap — the behavior uniform rows got from clamping.
	@Test func pointsPastEitherEndClampToTheEdgeKey() throws {
		let m = metrics(shoulderedKeymap(leading: [.init(.blank)]))
		let rowY = m.keyCapHeight * 0.5
		#expect(m.key(at: CGPoint(x: 9, y: rowY)) == KeyDefinition("Q"))
		#expect(m.key(at: CGPoint(x: 393, y: rowY)) == KeyDefinition("P"))
	}

	@Test func touchesWellClearOfTheKeyboardCancel() throws {
		let m = metrics(shoulderedKeymap(leading: [.init(.blank)]))
		#expect(m.key(at: CGPoint(x: 200, y: m.keyCapHeight * 3 + m.slop + 10)) == nil)
	}
}
