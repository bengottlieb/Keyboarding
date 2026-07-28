//
//  KeyAvailabilityTests.swift
//  Keyboarding
//
//  The rule behind dimming: which keys read as unavailable for a given set.
//  The visuals are KeyCapView's, but the decision is here so it can be pinned
//  down — the costly mistakes are dimming a key that works and dimming keys a
//  host never asked to constrain.
//

import Testing
import SwiftUI
@testable import Keyboarding

struct KeyAvailabilityTests {
	@Test func noSetLeavesEveryKeyAvailable() {
		// The default for every host that has never heard of this feature.
		for key: KeyDefinition in ["Q", "M", "A"] {
			#expect(!key.isUnavailable(given: nil))
		}
		#expect(!KeyDefinition(.delete).isUnavailable(given: nil))
	}

	@Test func lettersOutsideTheSetAreUnavailable() {
		let available: Set<String> = ["A", "E", "R"]
		#expect(!KeyDefinition("A").isUnavailable(given: available))
		#expect(!KeyDefinition("R").isUnavailable(given: available))
		#expect(KeyDefinition("Q").isUnavailable(given: available))
		#expect(KeyDefinition("Z").isUnavailable(given: available))
	}

	@Test func matchingIgnoresCase() {
		#expect(!KeyDefinition("a").isUnavailable(given: ["A"]))
		#expect(!KeyDefinition("A").isUnavailable(given: ["a"]))
	}

	/// Dimming delete or dismiss would read as "you are stuck", which is never
	/// what a constrained letter set means.
	@Test func nonLetterKeysNeverDim() {
		let nothingFits: Set<String> = []
		for key in [KeyDefinition(.delete), KeyDefinition(.dismiss), KeyDefinition(.pencil), KeyDefinition(.space)] {
			#expect(!key.isUnavailable(given: nothingFits))
		}
	}

	/// An empty set is a real answer — "nothing fits here" — and must not be
	/// confused with nil, which means the host isn't constraining at all.
	@Test func emptySetDimsEveryLetter() {
		#expect(KeyDefinition("A").isUnavailable(given: []))
		#expect(KeyDefinition("Z").isUnavailable(given: []))
	}
}
