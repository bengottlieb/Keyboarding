//
//  KeyLongPressTests.swift
//  KeyboardingTests
//
//  A held key belongs to the host's block, not to the key: the two costly
//  mistakes are running the block for a finger that moved on, and letting the
//  key also commit once the block has run (delete-and-clear-the-puzzle).
//

import Testing
import Foundation
@testable import Keyboarding

@MainActor
@Suite("Holding a key runs the host's block")
struct KeyLongPressTests {
	private let delete = KeyDefinition(.delete)
	private let letter: KeyDefinition = "A"

	@Test("a finger resting on its key runs the block, and the key doesn't commit")
	func restingFingerRunsBlock() async throws {
		let touches = KeyboardTouchModel()
		var held: KeyDefinition?
		touches.update(origin: delete, target: delete, click: false, haptic: false)
		touches.armLongPress(origin: delete) { held = $0; return true }

		try await Task.sleep(for: KeyboardTouchModel.longPressDuration + .milliseconds(120))
		#expect(held == delete)
		#expect(touches.consumedLongPress(origin: delete))
		// Spent: the press feedback is gone, and the second ask is false — the
		// touch can't be consumed twice.
		#expect(touches.visible.isEmpty)
		#expect(!touches.consumedLongPress(origin: delete))
	}

	@Test("sliding to another key cancels the hold")
	func slidingCancelsTheHold() async throws {
		let touches = KeyboardTouchModel()
		var ran = false
		touches.update(origin: delete, target: delete, click: false, haptic: false)
		touches.armLongPress(origin: delete) { _ in ran = true; return true }
		touches.update(origin: delete, target: letter, click: false, haptic: false)

		try await Task.sleep(for: KeyboardTouchModel.longPressDuration + .milliseconds(120))
		#expect(!ran)
		#expect(!touches.consumedLongPress(origin: delete))
	}

	@Test("sliding away and back doesn't re-arm the hold")
	func slidingBackDoesNotRearm() async throws {
		let touches = KeyboardTouchModel()
		var ran = false
		touches.update(origin: delete, target: delete, click: false, haptic: false)
		touches.armLongPress(origin: delete) { _ in ran = true; return true }
		touches.update(origin: delete, target: letter, click: false, haptic: false)
		touches.update(origin: delete, target: delete, click: false, haptic: false)
		touches.armLongPress(origin: delete) { _ in ran = true; return true }

		try await Task.sleep(for: KeyboardTouchModel.longPressDuration + .milliseconds(120))
		#expect(!ran)
	}

	@Test("a block that declines the key leaves the touch alone")
	func decliningBlockLeavesTheTouch() async throws {
		let touches = KeyboardTouchModel()
		touches.update(origin: letter, target: letter, click: false, haptic: false)
		touches.armLongPress(origin: letter) { _ in false }

		try await Task.sleep(for: KeyboardTouchModel.longPressDuration + .milliseconds(120))
		#expect(!touches.consumedLongPress(origin: letter))
		// Still pressed, so releasing types the letter as it always did.
		#expect(touches.visible[letter.id] == letter)
	}

	@Test("lifting before the hold lands cancels it")
	func liftingCancelsTheHold() async throws {
		let touches = KeyboardTouchModel()
		var ran = false
		touches.update(origin: delete, target: delete, click: false, haptic: false)
		touches.armLongPress(origin: delete) { _ in ran = true; return true }
		touches.end(origin: delete)

		try await Task.sleep(for: KeyboardTouchModel.longPressDuration + .milliseconds(120))
		#expect(!ran)
	}
}
