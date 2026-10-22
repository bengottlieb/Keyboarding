//
//  KeyAlternatesTests.swift
//  KeyboardingTests
//
//  A held letter key's row of alternates: the host decides what each key
//  offers (and its own long-press claim wins), the row grows away from the
//  nearer edge and stays on the keyboard, the choice follows the finger, and
//  only a lift on the row types anything.
//

import Testing
import Foundation
import CoreGraphics
@testable import Keyboarding

@MainActor
@Suite("Holding a letter key offers its alternates")
struct KeyAlternatesTests {
	private let accents = KeyAlternatesProvider { key in key.string == "E" ? ["E", "È", "É"] : [] }

	@Test("alternates resolve per key, and only for letter keys")
	func alternatesResolvePerKey() {
		#expect(KeyHoldOutcome.resolve("E", longPress: nil, alternates: accents) == .alternates(["E", "È", "É"]))
		#expect(KeyHoldOutcome.resolve("Q", longPress: nil, alternates: accents) == .none)
		let everything = KeyAlternatesProvider { _ in ["1", "2"] }
		#expect(KeyHoldOutcome.resolve(KeyDefinition(.delete), longPress: nil, alternates: everything) == .none)
		#expect(KeyHoldOutcome.resolve("E", longPress: nil, alternates: nil) == .none)
	}

	@Test("the host's long-press claim wins over the row; a declined key still gets one")
	func longPressClaimWins() {
		var claimed: [KeyDefinition] = []
		let deleteOnly = KeyLongPressHandler { key in claimed.append(key); return key.type == .delete }
		let all = KeyAlternatesProvider { _ in ["A", "B"] }
		#expect(KeyHoldOutcome.resolve(KeyDefinition(.delete), longPress: deleteOnly, alternates: all) == .claimed)
		#expect(KeyHoldOutcome.resolve("A", longPress: deleteOnly, alternates: all) == .alternates(["A", "B"]))
		#expect(claimed == [KeyDefinition(.delete), "A"])
	}

	@Test("VoiceOver actions are the alternates less the key's own letter")
	func accessibilityChoices() {
		#expect(KeyHoldOutcome.accessibilityChoices(for: "E", alternates: accents) == ["È", "É"])
		#expect(KeyHoldOutcome.accessibilityChoices(for: "Q", alternates: accents).isEmpty)
	}

	@Test("hold, slide, lift types the choice; lifting in place types the key's own letter")
	func releaseSendsTheSelection() async throws {
		let touches = KeyboardTouchModel()
		let (row, key) = (KeyAlternatesGeometryTests.row(for: "E", choices: ["E", "È", "É"]), KeyDefinition("E"))
		touches.update(origin: key, target: key, click: false, haptic: false)
		touches.armLongPress(origin: key) { origin in touches.openAlternates(row, origin: origin); return true }
		try await Task.sleep(for: KeyboardTouchModel.longPressDuration + .milliseconds(120))
		#expect(touches.hasAlternates(origin: key))
		// The row replaced the key's preview.
		#expect(touches.visible.isEmpty)
		#expect(touches.alternateRows[key.id]?.selection == "E")

		let third = CGPoint(x: row.cellRect(at: 2).midX, y: row.frame.midY)
		touches.moveAlternates(origin: key, to: third)
		#expect(touches.alternateRows[key.id]?.selectedIndex == 2)
		#expect(touches.finishAlternates(origin: key, at: third) == "É")
		#expect(!touches.hasAlternates(origin: key))

		let inPlace = KeyboardTouchModel()
		inPlace.openAlternates(row, origin: key)
		#expect(inPlace.finishAlternates(origin: key, at: CGPoint(x: row.hit.midX, y: row.hit.midY)) == "E")
	}

	@Test("each change of choice plays the haptic, from the touch; staying put or leaving the row doesn't")
	func hapticOnChange() {
		let row = KeyAlternatesGeometryTests.row(for: "E", choices: ["E", "È", "É"])
		let key = KeyDefinition("E")
		let touches = KeyboardTouchModel()
		var ticks = 0
		touches.alternateHaptic = { ticks += 1 }
		touches.openAlternates(row, origin: key)
		let second = CGPoint(x: row.cellRect(at: 1).midX, y: row.frame.midY)
		touches.moveAlternates(origin: key, to: second, haptic: true)
		touches.moveAlternates(origin: key, to: CGPoint(x: second.x + 1, y: second.y), haptic: true)
		#expect(ticks == 1)
		touches.moveAlternates(origin: key, to: CGPoint(x: row.cellRect(at: 2).midX, y: row.frame.midY), haptic: true)
		#expect(ticks == 2)
		touches.moveAlternates(origin: key, to: CGPoint(x: row.frame.midX, y: row.frame.minY - 20), haptic: true)
		#expect(ticks == 2)
		// Haptics turned off in the style: the choice still follows, silently.
		touches.moveAlternates(origin: key, to: second, haptic: false)
		#expect(ticks == 2)
		#expect(touches.alternateRows[key.id]?.selection == "È")
	}

	@Test("the keyboard dims while a row is open, and not once it closes or is cancelled")
	func dimmingFollowsTheRow() {
		let row = KeyAlternatesGeometryTests.row(for: "E", choices: ["E", "È", "É"])
		let key = KeyDefinition("E")
		let touches = KeyboardTouchModel()
		#expect(!touches.isShowingAlternates)
		touches.openAlternates(row, origin: key)
		#expect(touches.isShowingAlternates)
		_ = touches.finishAlternates(origin: key, at: .zero)
		#expect(!touches.isShowingAlternates)
		touches.openAlternates(row, origin: key)
		touches.cancelAll()
		#expect(!touches.isShowingAlternates)
	}

	@Test("lifting off the row, or a cancelled touch, types nothing")
	func cancelSendsNothing() {
		let row = KeyAlternatesGeometryTests.row(for: "E", choices: ["E", "È", "É"])
		let key = KeyDefinition("E")
		let touches = KeyboardTouchModel()
		touches.openAlternates(row, origin: key)
		let above = CGPoint(x: row.frame.midX, y: row.frame.minY - 10)
		touches.moveAlternates(origin: key, to: above)
		#expect(touches.alternateRows[key.id]?.selection == nil)
		#expect(touches.finishAlternates(origin: key, at: above) == nil)

		let token = UUID()
		touches.update(origin: key, target: key, click: false, haptic: false, touchID: token)
		touches.openAlternates(row, origin: key)
		touches.cancelIfActive(origin: key, touchID: token)
		#expect(!touches.hasAlternates(origin: key))
		#expect(touches.finishAlternates(origin: key, at: CGPoint(x: row.cellRect(at: 1).midX, y: row.frame.midY)) == nil)
	}
}
