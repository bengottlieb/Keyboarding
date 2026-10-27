//
//  KeyAccessibilityActionsTests.swift
//  KeyboardingTests
//
//  A key's VoiceOver custom actions: none at all for a key with no alternates
//  (an empty list still made VoiceOver say "Actions available"), and exactly its
//  choices — no blanks, no repeats, not its own letter — for one that has some.
//

import Testing
@testable import Keyboarding

@MainActor
@Suite("A key offers VoiceOver actions only when it has alternates")
struct KeyAccessibilityActionsTests {
	private let accents = KeyAlternatesProvider { key in key.string == "E" ? ["E", "È", "É"] : [] }

	private func actions(for key: KeyDefinition, alternates: KeyAlternatesProvider?) -> KeyAccessibilityActions {
		KeyAccessibilityActions(choices: KeyHoldOutcome.accessibilityChoices(for: key, alternates: alternates)) { _ in }
	}

	@Test("a key with no choices gets no custom actions")
	func noChoicesNoActions() {
		#expect(!actions(for: "Q", alternates: accents).attachesActions)
		#expect(!actions(for: "Q", alternates: nil).attachesActions)
		#expect(!actions(for: KeyDefinition(.delete), alternates: KeyAlternatesProvider { _ in ["1"] }).attachesActions)
		// A row that offers only the key's own letter has nothing left to act on.
		#expect(!actions(for: "A", alternates: KeyAlternatesProvider { _ in ["A"] }).attachesActions)
	}

	@Test("a key with alternates gets exactly its choices")
	func alternatesAreTheActions() {
		let modifier = actions(for: "E", alternates: accents)
		#expect(modifier.attachesActions)
		#expect(modifier.choices == ["È", "É"])
	}

	@Test("blank and repeated alternates are dropped, in the row's order")
	func blanksAndRepeatsDropped() {
		let messy = KeyAlternatesProvider { _ in ["", "È", " ", "E", "É", "È", "\n", "É"] }
		#expect(KeyHoldOutcome.accessibilityChoices(for: "E", alternates: messy) == ["È", "É"])
		let blanks = KeyAlternatesProvider { _ in ["", " "] }
		#expect(!actions(for: "E", alternates: blanks).attachesActions)
	}
}
