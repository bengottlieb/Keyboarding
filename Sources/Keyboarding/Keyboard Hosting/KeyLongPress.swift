//
//  KeyLongPress.swift
//  Keyboarding
//
//  A block a host can hang off any key: hold that key and the block runs
//  instead of the key committing. Supplied as a closure with creation-site
//  identity (like KeySender and NextKeyProvider), so installing one leaves the
//  environment stable and never rebuilds the keycaps.
//

import SwiftUI

public struct KeyLongPressHandler: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let handle: @MainActor (KeyDefinition) -> Bool

	/// Run the host's block for a held key. Returning true consumes the touch:
	/// the key is not sent when the finger lifts, and its press feedback ends at
	/// once — a hold that opened an alert must not also type.
	@MainActor public func callAsFunction(_ key: KeyDefinition) -> Bool { handle(key) }

	// Identified by creation site only (like KeySender), so a handler rebuilt on
	// every render of its host compares equal and the environment stays stable.
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}

	public init(_ handle: @MainActor @escaping (KeyDefinition) -> Bool, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.handle = handle
	}
}

extension EnvironmentValues {
	/// The host's long-press block, asked about whichever key is being held.
	@Entry public var keyLongPress: KeyLongPressHandler? = nil
}
