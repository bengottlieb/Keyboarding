//
//  NextKeyProvider.swift
//  Keyboarding
//
//  Typing assist's input: the letter the host expects next, supplied as a
//  closure rather than a value.
//
//  A value would have to be republished on every keystroke, and the keyboard
//  reading it in `body` would rebuild all its keycaps — and their gestures —
//  each letter typed. As a closure with creation-site identity (like KeySender
//  and GlideHandler) the environment never changes, and the keyboard asks for
//  the letter once, inside the commit path, where no view is being evaluated.
//

import SwiftUI

public struct NextKeyProvider: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let provide: @MainActor () -> String?

	/// The expected next letter right now, or nil for no assist. Call only from
	/// event handlers — calling it while building a view would register the
	/// host's observable reads against that view, which is the whole thing this
	/// type exists to avoid.
	@MainActor public func callAsFunction() -> String? { provide() }

	// Identified by creation site only (like KeySender), so a provider rebuilt on
	// every render of its host compares equal and the environment stays stable.
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}

	public init(_ provide: @MainActor @escaping () -> String?, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.provide = provide
	}
}
