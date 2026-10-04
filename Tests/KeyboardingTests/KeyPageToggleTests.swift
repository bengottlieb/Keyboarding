//
//  KeyPageToggleTests.swift
//  Keyboarding
//
//  A two-page keyboard (letters, then digits and symbols behind "123") and the
//  host-labelled command keys that sit on both pages.
//

import Testing
import SwiftUI
@testable import Keyboarding

@MainActor
struct KeyPageToggleTests {
	private let letters = Keymap(rows: [["Q", "W", "E"], [KeyDefinition(.pageToggle(title: "123", spokenLabel: "Numbers"))]])
	private let numbers = Keymap(rows: [["1", "2", "3"], [KeyDefinition(.pageToggle(title: "ABC", spokenLabel: "Letters"))]])

	@Test func theAlternateShowsOnlyWhileAskedForAndSupplied() {
		#expect(Keymap.page(letters, alternate: numbers, showingAlternate: false) == letters)
		#expect(Keymap.page(letters, alternate: numbers, showingAlternate: true) == numbers)
		// A host that stops supplying the second page never strands the reader on it.
		#expect(Keymap.page(letters, alternate: nil, showingAlternate: true) == letters)
	}

	/// "123" and "ABC" sit in the same place but are different keys: were they
	/// equal, SwiftUI would keep drawing "123" after the page had turned.
	@Test func eachPagesToggleIsItsOwnKey() {
		let toLetters = KeyDefinition(.pageToggle(title: "ABC", spokenLabel: "Letters"))
		let toNumbers = KeyDefinition(.pageToggle(title: "123", spokenLabel: "Numbers"))
		#expect(toLetters != toNumbers)
		#expect(toLetters.id != toNumbers.id)
		#expect(toLetters.string == nil, "a toggle never types its label")
	}

	@Test func commandKeysAreToldApartByID() {
		let flip = KeyDefinition(.command(id: "flip", title: "Flip"))
		let back = KeyDefinition(.command(id: "back", systemImage: "chevron.left"))
		#expect(flip.id != back.id)
		#expect(flip.type == KeyDefinition(.command(id: "flip", title: "Flip")).type)
		#expect(back.type.imageName == "chevron.left")
		#expect(flip.string == nil, "a command never types its title")
		// Neither dims against a host's available letters: only letters do.
		#expect(!flip.isUnavailable(given: []))
	}
}
