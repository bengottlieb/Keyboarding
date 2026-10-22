//
//  KeyAlternatesProvider.swift
//  Keyboarding
//
//  The characters a held letter key offers: hold the key past the long-press
//  duration and a row of them pops up above it; slide onto one and lift to type
//  it, lift off the row to type nothing. The original Crosswords keyboards'
//  accented-letter popup.
//
//  Supplied as a closure with creation-site identity, like KeySender and
//  NextKeyProvider, so installing one leaves the environment stable and never
//  rebuilds the keycaps. Unlike NextKeyProvider it is also asked while the
//  keyboard is built (for each key's VoiceOver actions), so it must be a pure
//  function of the key — a fixed table, not observable state.
//

import SwiftUI

public struct KeyAlternatesProvider: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let provide: @MainActor (KeyDefinition) -> [String]

	/// The choices a hold on this key offers, in the order the row shows them,
	/// or none for a key that has no row. A choice is typed as a letter key with
	/// that string. Including the key's own letter lets the row highlight it.
	@MainActor public func callAsFunction(_ key: KeyDefinition) -> [String] { provide(key) }

	// Identified by creation site only (like KeySender), so a provider rebuilt on
	// every render of its host compares equal and the environment stays stable.
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}

	public init(_ provide: @MainActor @escaping (KeyDefinition) -> [String], file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.provide = provide
	}
}

extension EnvironmentValues {
	/// The host's alternates for a held letter key (see KeyAlternatesProvider).
	@Entry public var keyAlternates: KeyAlternatesProvider? = nil
}

/// What a hold on a key turns into. The host's long-press block is asked first
/// and wins outright, so a key it claims never gets a row; only a letter key the
/// host declined, with alternates to offer, opens one.
enum KeyHoldOutcome: Equatable {
	case claimed
	case alternates([String])
	case none

	@MainActor static func resolve(_ key: KeyDefinition, longPress: KeyLongPressHandler?, alternates: KeyAlternatesProvider?) -> Self {
		if longPress?(key) == true { return .claimed }
		guard key.type == .letter, let choices = alternates?(key), !choices.isEmpty else { return .none }
		return .alternates(choices)
	}

	/// The VoiceOver actions a key offers: its alternates less its own letter,
	/// which the key's default action already types.
	@MainActor static func accessibilityChoices(for key: KeyDefinition, alternates: KeyAlternatesProvider?) -> [String] {
		guard key.type == .letter, let alternates else { return [] }
		return alternates(key).filter { $0 != key.string }
	}
}
