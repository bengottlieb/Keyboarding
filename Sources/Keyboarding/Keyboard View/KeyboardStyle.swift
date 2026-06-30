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
	/// How much the assisted (`keyboardNextKey`) key's hit area grows, as a fraction
	/// of a key's width. The visible keycap is unchanged; only the touch target bleeds
	/// over the neighbors to bias "fat finger" taps toward the expected letter.
	public var nextKeyHitExpansion: CGFloat

	public init(background: Color = .clear, keyFace: Color = Color.gray.opacity(0.22),
	            keyInk: Color = .primary, specialInk: Color = .secondary, cornerRadius: CGFloat = 6,
	            enableHaptics: Bool = true, nextKeyHitExpansion: CGFloat = 0.5) {
		self.background = background
		self.keyFace = keyFace
		self.keyInk = keyInk
		self.specialInk = specialInk
		self.cornerRadius = cornerRadius
		self.enableHaptics = enableHaptics
		self.nextKeyHitExpansion = nextKeyHitExpansion
	}

	public static let `default` = KeyboardStyle()
}

public extension EnvironmentValues {
	@Entry var keyboardStyle: KeyboardStyle = .default
	/// The letter whose key should get an enlarged hit target (typing assist), or nil.
	@Entry var keyboardNextKey: String? = nil
	/// Debug only: when true, the enlarged hit area of `keyboardNextKey` is drawn so
	/// it can be seen and tuned. Production keeps the assist invisible.
	@Entry var keyboardAssistDebug: Bool = false
}
