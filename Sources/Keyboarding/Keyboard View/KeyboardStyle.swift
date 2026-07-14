//
//  KeyboardStyle.swift
//  Keyboarding
//
//  Themeable colors and shape for the on-screen keyboard. Inject one with
//  `.environment(\.keyboardStyle, …)`; the default preserves the built-in look.
//

import SwiftUI

/// The typeface for keycap glyphs. Pass an empty `family` for the system font
/// of the given design; the size is chosen by the keyboard relative to key width.
public struct KeyboardFont: Sendable, Equatable {
	public var family: String
	public var design: Font.Design
	public var weight: Font.Weight

	public init(family: String = "", design: Font.Design = .rounded, weight: Font.Weight = .bold) {
		self.family = family
		self.design = design
		self.weight = weight
	}

	public func font(size: CGFloat) -> Font {
		family.isEmpty ? .system(size: size, weight: weight, design: design)
					   : .custom(family, size: size).weight(weight)
	}
}

public struct KeyboardStyle: Sendable, Equatable {
	/// Backdrop behind the keys.
	public var background: Color
	/// Key face fill.
	public var keyFace: Color
	/// Letter-key glyph color.
	public var keyInk: Color
	/// Glyph color for special keys (delete, pencil, dismiss, …).
	public var specialInk: Color
	/// Keycap glyph typeface.
	public var keyFont: KeyboardFont
	/// Key corner radius.
	public var cornerRadius: CGFloat
	/// Whether key taps produce selection haptics.
	public var enableHaptics: Bool
	/// Whether a finger landing on a key plays the system keyboard click. Played at
	/// touch-down (like the system keyboard), not at commit — the sound is the
	/// strongest "the key registered" cue, so it must not wait for touch-up.
	public var enableKeySounds: Bool
	/// How much the assisted (`keyboardNextKey`) key's hit area grows, as a fraction
	/// of a key's width. The visible keycap is unchanged; only the touch target bleeds
	/// over the neighbors to bias "fat finger" taps toward the expected letter.
	public var nextKeyHitExpansion: CGFloat

	public init(background: Color = .clear, keyFace: Color = Color.gray.opacity(0.22),
	            keyInk: Color = .primary, specialInk: Color = .secondary, keyFont: KeyboardFont = .init(),
	            cornerRadius: CGFloat = 6, enableHaptics: Bool = true, enableKeySounds: Bool = true,
	            nextKeyHitExpansion: CGFloat = 0.5) {
		self.background = background
		self.keyFace = keyFace
		self.keyInk = keyInk
		self.specialInk = specialInk
		self.keyFont = keyFont
		self.cornerRadius = cornerRadius
		self.enableHaptics = enableHaptics
		self.enableKeySounds = enableKeySounds
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
