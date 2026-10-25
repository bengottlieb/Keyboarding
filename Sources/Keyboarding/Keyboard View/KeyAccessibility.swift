//
//  KeyAccessibility.swift
//  Keyboarding
//
//  What VoiceOver hears for a key, the way the system keyboard (and the
//  original Crosswords keyboard) says it. Letters and Delete are keyboard keys,
//  not buttons: that trait is what lets VoiceOver's touch typing type a key on
//  lift instead of asking for a double tap. A letter reads lowercase — "q", not
//  "capital Q" — with its phonetic name as the hint, said after a pause the way
//  the system keyboard says it. Function keys stay buttons, named for what they
//  do.
//

import SwiftUI

extension KeyDefinition {
	/// Keys VoiceOver touch typing types on lift: the letters and Delete.
	var isTypedKey: Bool {
		switch type {
		case .letter: string != nil
		case .delete: true
		default: false
		}
	}

	var accessibilityTraits: AccessibilityTraits { isTypedKey ? .isKeyboardKey : .isButton }

	var accessibilityLabel: String {
		if let string { return string.lowercased() }
		switch type {
		case .delete: return "Backspace"
		case .dismiss: return "Dismiss keyboard"
		case .tab: return "Tab"
		case .enter: return "Return"
		case .space: return "Space"
		case .navigation: return "Navigation"
		case .pencil: return "Pencil"
		case .skip: return "Skip"
		case .custom: return "Custom key"
		case .command(let id, let title, _): return title ?? id.capitalized
		case .pageToggle(_, let spokenLabel): return spokenLabel
		case .letter, .blank: return ""
		}
	}

	/// The phonetic name for an A–Z letter, then "unavailable" for a letter the
	/// host has dimmed — a hint, not `.isNotEnabled`, because the key still types.
	func accessibilityHint(isUnavailable: Bool) -> String {
		switch (phoneticName, isUnavailable) {
		case (let name?, true): "\(name), unavailable"
		case (let name?, false): name
		case (nil, true): "Unavailable"
		case (nil, false): ""
		}
	}

	/// The NATO alphabet's word for this letter key, nil for anything else.
	var phoneticName: String? {
		guard type == .letter, let string, string.count == 1 else { return nil }
		return Self.phonetic[string.uppercased()]
	}

	private static let phonetic: [String: String] = [
		"A": "Alpha", "B": "Bravo", "C": "Charlie", "D": "Delta", "E": "Echo", "F": "Foxtrot",
		"G": "Golf", "H": "Hotel", "I": "India", "J": "Juliett", "K": "Kilo", "L": "Lima",
		"M": "Mike", "N": "November", "O": "Oscar", "P": "Papa", "Q": "Quebec", "R": "Romeo",
		"S": "Sierra", "T": "Tango", "U": "Uniform", "V": "Victor", "W": "Whiskey", "X": "X-ray",
		"Y": "Yankee", "Z": "Zulu",
	]
}
