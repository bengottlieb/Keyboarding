//
//  GlideHandler.swift
//  Keyboarding
//
//  Opt-in glide (swipe) typing. Inject a handler via `.environment(\.keyboardGlide,
//  GlideHandler { stroke in … })` to enable it: any drag that traverses more than
//  one letter key is then delivered here as a GlideStroke instead of committing
//  the release key (single-key touches still tap normally). With no handler the
//  keyboard keeps its classic slide-to-retarget behavior.
//

import SwiftUI

public struct GlideHandler: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let handle: @MainActor (GlideStroke) -> Void

	@MainActor public func callAsFunction(_ stroke: GlideStroke) {
		handle(stroke)
	}

	// Identified by creation site only (like KeySender), so a handler rebuilt on
	// every render of its host compares equal and the environment stays stable.
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}

	public init(_ handle: @MainActor @escaping (GlideStroke) -> Void, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.handle = handle
	}
}

public extension EnvironmentValues {
	/// Non-nil enables glide typing; the handler receives each completed stroke.
	@Entry var keyboardGlide: GlideHandler? = nil
}
