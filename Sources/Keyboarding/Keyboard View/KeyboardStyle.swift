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

/// How the preview above a pressed key is drawn.
public enum KeyPreviewStyle: Sendable, Equatable {
	/// A balloon whose shoulders sweep down into a stem the width of the key,
	/// ending over the keycap and hiding it — the system keyboard's shape, and
	/// the original Crosswords keyboard's. The key reads as lifting off.
	case stemmed
	/// A detached rounded rectangle floating above the key, which stays visible
	/// and tinted underneath.
	case floating
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
	/// How far from the assisted (`keyboardNextKey`) key a near-miss is still taken
	/// for it, as a fraction of a key's width. Nothing about the keyboard changes
	/// while typing: the substitution happens once, at commit, and only for a press
	/// that qualifies as a fast-burst slip (see `KeyboardTouchModel.allowsAssist`).
	public var nextKeyHitExpansion: CGFloat
	/// Shape of the preview shown above a pressed letter key.
	public var keyPreview: KeyPreviewStyle
	/// How far a letter key fades when `keyboardAvailableLetters` excludes it.
	/// One opacity rather than a second palette, so the fade reads as the same
	/// keyboard dimmed and every theme gets it without adding colors.
	public var unavailableKeyOpacity: CGFloat

	public init(background: Color = .clear, keyFace: Color = Color.gray.opacity(0.22),
	            keyInk: Color = .primary, specialInk: Color = .secondary, keyFont: KeyboardFont = .init(),
	            cornerRadius: CGFloat = 6, enableHaptics: Bool = true, enableKeySounds: Bool = true,
	            nextKeyHitExpansion: CGFloat = 0.5, keyPreview: KeyPreviewStyle = .stemmed,
	            unavailableKeyOpacity: CGFloat = 0.3) {
		self.background = background
		self.keyFace = keyFace
		self.keyInk = keyInk
		self.specialInk = specialInk
		self.keyFont = keyFont
		self.cornerRadius = cornerRadius
		self.enableHaptics = enableHaptics
		self.enableKeySounds = enableKeySounds
		self.nextKeyHitExpansion = nextKeyHitExpansion
		self.keyPreview = keyPreview
		self.unavailableKeyOpacity = unavailableKeyOpacity
	}

	public static let `default` = KeyboardStyle()
}

public extension EnvironmentValues {
	@Entry var keyboardStyle: KeyboardStyle = .default
	/// Asked, at commit time, for the letter typing assist should correct toward —
	/// nil (or a provider returning nil) turns the assist off. A closure, not a
	/// value: see NextKeyProvider for why.
	@Entry var keyboardNextKey: NextKeyProvider? = nil
	/// Debug only: when true, the region where a near-miss is corrected toward
	/// `keyboardNextKey` is drawn so it can be seen and tuned. Production keeps the
	/// assist invisible.
	@Entry var keyboardAssistDebug: Bool = false
	/// Asked, as each keycap renders, for the letter keys that can usefully be
	/// typed right now; every other letter key fades to
	/// `KeyboardStyle.unavailableKeyOpacity`. A closure, not a value: see
	/// AvailableLettersProvider for why, and for what it has to read.
	///
	/// Nil — or a provider returning nil — means "unconstrained": no key is
	/// dimmed, so a host that never sets this sees the keyboard it always had.
	/// An EMPTY set is not the same thing:
	/// it says nothing fits here, and dims every letter.
	///
	/// This is a HINT, not a lock. Dimmed keys still type, still glide, and keep
	/// their hit targets: a host's notion of "available" is usually a dictionary,
	/// and a user is entitled to type a word it doesn't know. Non-letter keys
	/// (delete, dismiss, pencil, custom) are never dimmed.
	@Entry var keyboardAvailableLetters: AvailableLettersProvider? = nil
}
