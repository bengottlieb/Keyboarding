//
//  KeyboardAccessibilityValueProvider.swift
//  Keyboarding
//
//  Supplies live VoiceOver values for stateful keys without making every
//  keyboard rebuild whenever the host's state changes.
//

import SwiftUI

public struct KeyboardAccessibilityValueProvider: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let provide: @MainActor (KeyDefinition) -> String?

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
