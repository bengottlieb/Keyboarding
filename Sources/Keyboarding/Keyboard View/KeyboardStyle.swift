//
//  KeyboardStyle.swift
//  Keyboarding
//
//  Themeable colors and shape for the on-screen keyboard. Inject one with
//  `.environment(\.keyboardStyle, …)`; the default preserves the built-in look.
//

import SwiftUI

public struct KeyboardStyle: Sendable, Equatable {
	/// Backdrop behind the keys.
	public var background: Color
	/// Key face fill.
	public var keyFace: Color
	/// Letter-key glyph color.
	public var keyInk: Color
	/// Glyph color for special keys (delete, pencil, dismiss, …).
	public var specialInk: Color
	/// Key corner radius.
	public var cornerRadius: CGFloat
	/// Whether key taps produce selection haptics.
	public var enableHaptics: Bool

	public init(background: Color = .clear, keyFace: Color = Color.gray.opacity(0.22),
	            keyInk: Color = .primary, specialInk: Color = .secondary, cornerRadius: CGFloat = 6,
	            enableHaptics: Bool = true) {
		self.background = background
		self.keyFace = keyFace
		self.keyInk = keyInk
		self.specialInk = specialInk
		self.cornerRadius = cornerRadius
		self.enableHaptics = enableHaptics
	}

	public static let `default` = KeyboardStyle()
}

public extension EnvironmentValues {
	@Entry var keyboardStyle: KeyboardStyle = .default
}
