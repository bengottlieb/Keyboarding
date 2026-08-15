//
//  AvailableLettersProvider.swift
//  Keyboarding
//
//  Key dimming's input: the letters worth typing right now, supplied as a
//  closure rather than a value.
//
//  Like NextKeyProvider, it carries creation-site identity, so a host that
//  rebuilds one on every render leaves the environment unchanged — and the
//  keyboard doesn't relay out or reinstall its 30 gestures because the set of
//  available letters moved.
//
//  UNLIKE NextKeyProvider, this one is called *while a view is being built*:
//  each keycap asks it, in its own body, whether it should dim. That's the
//  point — the host's dependency lands on the keycaps, so a set that changes
//  per keystroke redraws caps instead of the whole keyboard and the screen
//  above it. It also means the closure has to read observable state (an
//  @Observable model, or a box the host writes into). One that captures a
//  plain value can never invalidate anything, so its dimming would freeze at
//  whatever the first render saw.
//

import SwiftUI

public struct AvailableLettersProvider: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let provide: @MainActor () -> Set<String>?

	/// The letters worth typing right now, or nil to dim nothing. Cheap, please:
	/// every letter keycap calls this during its own render.
	@MainActor public func callAsFunction() -> Set<String>? { provide() }

	// Identified by creation site only (like KeySender and NextKeyProvider), so a
	// provider rebuilt on every render of its host compares equal and the
	// environment stays stable.
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}

	public init(_ provide: @MainActor @escaping () -> Set<String>?, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.provide = provide
	}
}
