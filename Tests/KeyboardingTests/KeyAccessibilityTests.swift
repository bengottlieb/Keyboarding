//
//  KeyAccessibilityTests.swift
//  Keyboarding
//
//  What VoiceOver hears for a key. The traits are the part that matters most:
//  a letter read as a button can only be typed with a double tap, while a
//  keyboard key types on lift under VoiceOver's touch typing.
//

import Testing
import SwiftUI
@testable import Keyboarding

struct KeyAccessibilityTests {
	@Test func lettersAndDeleteAreKeyboardKeys() {
		for key: KeyDefinition in ["Q", "A", "M", "É", "1"] {
			#expect(key.accessibilityTraits == .isKeyboardKey)
		}
		#expect(KeyDefinition(.delete).accessibilityTraits == .isKeyboardKey)
	}

	@Test func functionKeysStayButtons() {
		let keys: [KeyDefinition] = [.init(.dismiss), .init(.pencil), .init(.skip), .init(.tab),
		                             .init(.command(id: "flip", title: "Flip")),
		                             .init(.pageToggle(title: "123", spokenLabel: "Numbers"))]
		for key in keys {
			#expect(key.accessibilityTraits == .isButton)
		}
	}

	/// Lowercase, as the system keyboard reads its keys: an uppercase label is
	/// spoken "capital Q".
	@Test func lettersReadLowercase() {
		#expect(KeyDefinition("Q").accessibilityLabel == "q")
		#expect(KeyDefinition("É").accessibilityLabel == "é")
		#expect(KeyDefinition("7").accessibilityLabel == "7")
	}

	@Test func functionKeysReadByName() {
		#expect(KeyDefinition(.delete).accessibilityLabel == "Backspace")
		#expect(KeyDefinition(.dismiss).accessibilityLabel == "Dismiss keyboard")
		#expect(KeyDefinition(.pencil).accessibilityLabel == "Pencil")
		#expect(KeyDefinition(.pageToggle(title: "123", spokenLabel: "Numbers")).accessibilityLabel == "Numbers")
	}

	@Test func lettersHintTheirPhoneticName() {
		#expect(KeyDefinition("A").accessibilityHint(isUnavailable: false) == "Alpha")
		#expect(KeyDefinition("x").accessibilityHint(isUnavailable: false) == "X-ray")
		#expect(KeyDefinition("Z").accessibilityHint(isUnavailable: false) == "Zulu")
		// Nothing to spell for a digit, an accent, or a function key.
		#expect(KeyDefinition("1").accessibilityHint(isUnavailable: false) == "")
		#expect(KeyDefinition("É").accessibilityHint(isUnavailable: false) == "")
		#expect(KeyDefinition(.delete).accessibilityHint(isUnavailable: false) == "")
	}

	/// A dimmed key still types, so it says so in the hint and keeps its trait.
	@Test func unavailableJoinsThePhoneticHint() {
		#expect(KeyDefinition("Q").accessibilityHint(isUnavailable: true) == "Quebec, unavailable")
		#expect(KeyDefinition("É").accessibilityHint(isUnavailable: true) == "Unavailable")
	}

	@Test func everyLetterHasAPhoneticName() {
		for scalar in UnicodeScalar("A").value...UnicodeScalar("Z").value {
			let letter = String(UnicodeScalar(scalar)!)
			#expect(KeyDefinition(stringLiteral: letter).phoneticName != nil, "\(letter)")
		}
	}
}
