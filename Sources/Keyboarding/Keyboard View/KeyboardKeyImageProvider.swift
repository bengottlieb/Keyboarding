//
//  KeyboardKeyImageProvider.swift
//  Keyboarding
//
//  Lets a host swap a key's glyph for a stateful one — a pencil key that shows
//  a pen while ink mode is on — without rebuilding the keyboard whenever the
//  host's state changes. Called from each keycap's body, so a cap re-renders
//  when the observable state it reads changes, and nothing else does.
//

import SwiftUI

public struct KeyboardKeyImageProvider: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let provide: @MainActor (KeyDefinition) -> String?

	/// The SF Symbol name to draw for `definition`, or nil to keep the key's own glyph.
	@MainActor public func callAsFunction(_ definition: KeyDefinition) -> String? { provide(definition) }

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}

	public init(_ provide: @MainActor @escaping (KeyDefinition) -> String?,
	            file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.provide = provide
	}
}
