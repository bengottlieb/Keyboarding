//
//  TypingAssistTests.swift
//  Keyboarding
//
//  Typing assist corrects a slip; it must never overrule an intention. These pin
//  both halves: the geometry that decides "close enough", and the timing rules
//  (ported from the original Crosswords keyboard) that decide whether the press
//  was a slip at all. A deliberate press — after a pause, held, or slid into
//  place — always types the key it landed on.
//

import Testing
import SwiftUI
@testable import Keyboarding

@MainActor
struct TypingAssistTests {
	private let keymap = Keymap(rows: [
		[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
		[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
		[ "Z", "X", "C", "V", "B", "N", "M" ]
	])

	private var metrics: KeyboardMetrics {
		KeyboardMetrics(keymap: keymap, width: 402, keyCapHeight: 54, horizontalMargin: 8)
	}

	private var expansion: CGFloat { metrics.keyCapWidth * 0.8 }

	// MARK: Geometry

	@Test func aNearMissBecomesTheExpectedLetter() throws {
		let m = metrics
		let r = try #require(m.rect(for: "R"))
		// Landed on R's inner edge, a hair from T — the classic fat-finger slip.
		let point = CGPoint(x: r.maxX - 2, y: r.midY)
		#expect(m.assisted("R", at: point, assistKey: "T", expansion: expansion) == KeyDefinition("T"))
	}

	@Test func aMissTooFarAwayIsLeftAlone() throws {
		let m = metrics
		let q = try #require(m.rect(for: "Q"))
		#expect(m.assisted("Q", at: CGPoint(x: q.midX, y: q.midY), assistKey: "T", expansion: expansion) == KeyDefinition("Q"))
	}

	/// Pressing the expected key squarely must come back unchanged — the assist is
	/// a substitution, and substituting a key for itself would still be a bug if it
	/// went through the wrong branch.
	@Test func pressingTheExpectedKeyIsUntouched() throws {
		let m = metrics
		let t = try #require(m.rect(for: "T"))
		#expect(m.assisted("T", at: CGPoint(x: t.midX, y: t.midY), assistKey: "T", expansion: expansion) == KeyDefinition("T"))
	}

	// MARK: Timing rules

	private func model(down: Date, lastCommit: Date?) -> KeyboardTouchModel {
		let touches = KeyboardTouchModel()
		if let lastCommit { touches.recordCommit(origin: "Q", now: lastCommit) }
		touches.update(origin: "R", target: "R", click: false, now: down)
		return touches
	}

	@Test func aSlipMidBurstQualifies() throws {
		let now = Date()
		let touches = model(down: now.addingTimeInterval(-0.05), lastCommit: now.addingTimeInterval(-0.1))
		#expect(touches.allowsAssist(origin: "R", now: now))
	}

	/// The guard that matters most: pause to think about a guess and your letter
	/// stands, however close it sits to the answer.
	@Test func aPressAfterThinkingDoesNotQualify() throws {
		let now = Date()
		let touches = model(down: now.addingTimeInterval(-0.05), lastCommit: now.addingTimeInterval(-1.5))
		#expect(!touches.allowsAssist(origin: "R", now: now))
	}

	@Test func theFirstPressOfASessionDoesNotQualify() throws {
		let now = Date()
		// No previous commit at all — there is no burst to be part of yet.
		let touches = model(down: now.addingTimeInterval(-0.05), lastCommit: nil)
		#expect(!touches.allowsAssist(origin: "R", now: now))
	}

	@Test func aHeldKeyDoesNotQualify() throws {
		let now = Date()
		let touches = model(down: now.addingTimeInterval(-1.0), lastCommit: now.addingTimeInterval(-0.1))
		#expect(!touches.allowsAssist(origin: "R", now: now))
	}

	/// Sliding to another key means the user is aiming deliberately; correcting
	/// that would undo the aim.
	@Test func slidingToAnotherKeyDisqualifies() throws {
		let now = Date()
		let touches = model(down: now.addingTimeInterval(-0.05), lastCommit: now.addingTimeInterval(-0.1))
		touches.update(origin: "R", target: "T", click: false, now: now)
		#expect(!touches.allowsAssist(origin: "R", now: now))
	}

	/// Committing starts the next press's burst clock and clears this finger, so a
	/// stale hold time can't qualify a later press.
	@Test func commitClearsThePressItRecorded() throws {
		let now = Date()
		let touches = model(down: now.addingTimeInterval(-0.05), lastCommit: now.addingTimeInterval(-0.1))
		touches.recordCommit(origin: "R", now: now)
		#expect(!touches.allowsAssist(origin: "R", now: now))
	}
}
