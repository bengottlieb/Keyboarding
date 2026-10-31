//
//  KeyTwoFingerHoldTests.swift
//  KeyboardingTests
//
//  The host's two-finger hold takes the keys it lands on — no letter, no
//  alternates, no glide, no key's own hold — while rolling typing, two
//  fingers briefly down at once, types every key as before.
//

import Testing
import Foundation
@testable import Keyboarding

@MainActor
@Suite("A two-finger hold on the keyboard")
struct KeyTwoFingerHoldTests {
	private let wait = KeyboardTouchModel.longPressDuration + .milliseconds(120)

	@Test("two fingers down keep both keys' holds from landing")
	func twoFingersSuspendHolds() async throws {
		let touches = KeyboardTouchModel()
		var held: [KeyDefinition] = []
		touches.update(origin: "A", target: "A", click: false, haptic: false, touchID: UUID())
		touches.armLongPress(origin: "A") { held.append($0); return true }
		touches.update(origin: "S", target: "S", click: false, haptic: false, touchID: UUID())
		touches.suspendHolds(true)
		touches.armLongPress(origin: "S") { held.append($0); return true }

		try await Task.sleep(for: wait)
		#expect(held.isEmpty)
	}

	@Test("a finger left down after the other lifts still never holds")
	func remainingFingerForfeitsItsHold() async throws {
		let touches = KeyboardTouchModel()
		var ran = false
		touches.update(origin: "A", target: "A", click: false, haptic: false, touchID: UUID())
		touches.update(origin: "S", target: "S", click: false, haptic: false, touchID: UUID())
		touches.suspendHolds(true)
		touches.end(origin: "S")
		touches.suspendHolds(false)
		touches.armLongPress(origin: "A") { _ in ran = true; return true }

		try await Task.sleep(for: wait)
		#expect(!ran)
	}

	@Test("rolling typing: both fingers' presses are still live, so each types on lift")
	func rollingTypingStillTypes() {
		let touches = KeyboardTouchModel()
		let first = UUID(), second = UUID()
		touches.update(origin: "A", target: "A", click: false, haptic: false, touchID: first)
		touches.update(origin: "S", target: "S", click: false, haptic: false, touchID: second)
		touches.suspendHolds(true)
		#expect(touches.isActive(origin: "A", touchID: first))
		touches.end(origin: "A")
		touches.suspendHolds(false)
		#expect(touches.isActive(origin: "S", touchID: second))
	}

	@Test("the hold landing ends every press still down, alternates and glides with them")
	func holdSpendsThePresses() {
		let touches = KeyboardTouchModel()
		let first = UUID(), second = UUID()
		touches.update(origin: "E", target: "E", click: false, haptic: false, touchID: first)
		touches.openAlternates(KeyAlternatesGeometryTests.row(for: "E", choices: ["E", "É"]), origin: "E")
		touches.update(origin: "S", target: "S", click: false, haptic: false, touchID: second)
		touches.glideSample(origin: "S", point: .zero, over: "S")

		touches.spendActiveTouches()
		#expect(!touches.isActive(origin: "E", touchID: first))
		#expect(!touches.isActive(origin: "S", touchID: second))
		#expect(touches.visible.isEmpty)
		#expect(touches.alternateRows.isEmpty)
		#expect(touches.glides.isEmpty)
	}

	@Test("a spent finger sliding before it lifts lights nothing and stays spent")
	func spentFingerStaysSpent() {
		let touches = KeyboardTouchModel()
		let finger = UUID()
		touches.update(origin: "A", target: "A", click: false, haptic: false, touchID: finger)
		touches.spendActiveTouches()
		touches.update(origin: "A", target: "Q", click: false, haptic: false, touchID: finger)
		#expect(touches.visible.isEmpty)
		#expect(!touches.isActive(origin: "A", touchID: finger))

		// Once it lifts, the next touch on that key is an ordinary press.
		touches.forget(touchID: finger)
		let next = UUID()
		touches.update(origin: "A", target: "A", click: false, haptic: false, touchID: next)
		#expect(touches.isActive(origin: "A", touchID: next))
	}
}
