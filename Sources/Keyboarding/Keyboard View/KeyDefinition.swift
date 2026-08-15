//
//  KeyDefinition.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 12/17/25.
//

import SwiftUI

public struct KeyDefinition: Sendable, Hashable, Identifiable, ExpressibleByStringLiteral {
	public let string: String?
	public let type: KeyType
	public let keyPress: KeyPress?
	/// How wide this key is, as a multiple of the keyboard's unit key width. A
	/// letter is 1; the function keys flanking a row take more, so the letters
	/// between them land on the same columns as the system keyboard.
	///
	/// Deliberately outside `==` and `hash`: a key is still the same key at a
	/// different width, and the touch model keys off `id`.
	public var width: CGFloat = 1

	public var id: String { string ?? type.id }

	/// This key at a different width (see `width`).
	public func width(_ width: CGFloat) -> Self {
		var copy = self
		copy.width = width
		return copy
	}

	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.type == rhs.type && lhs.string == rhs.string
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(type)
		hasher.combine(string)
	}
	
	public init(stringLiteral value: StringLiteralType) {
		string = value
		type = .letter
		keyPress = nil
	}
	
	public init(_ type: KeyType) {
		self.type = type
		keyPress = nil
		string = nil
	}
	
	public init(keyPress: KeyPress) {
		self.keyPress = keyPress
		switch keyPress.key {
		case .delete, .deleteForward:
			type = .delete
			string = nil
			
		case .leftArrow, .rightArrow, .downArrow, .upArrow:
			type = .navigation
			string = nil

		default:
			type = .letter
			string = keyPress.characters

		}
	}
	
	public var isShifted: Bool {
		guard let keyPress else { return false }
		return keyPress.modifiers.contains(.shift)
	}
	
	public var action: (() -> Void)? {
		switch type {
		case .custom(_, _, let action): action
		default: nil
		}
	}

	/// Whether this key should read as unavailable against a host's set of
	/// available letters (see `EnvironmentValues.keyboardAvailableLetters`).
	///
	/// Nil means the host is not constraining anything, so nothing is
	/// unavailable. Only letter keys ever are: dimming delete or dismiss would
	/// suggest the user is stuck with what they have typed.
	///
	/// Both sides are case-folded, not just the keycap. Folding one side would
	/// mean a host that passes lowercase dims every key — and an all-dimmed
	/// keyboard is indistinguishable from the legitimate empty-set answer, so
	/// the mistake would look like a feature working. The scan is over at most
	/// an alphabet.
	func isUnavailable(given availableLetters: Set<String>?) -> Bool {
		guard let availableLetters, type == .letter, let string else { return false }
		let wanted = string.uppercased()
		return !availableLetters.contains { $0.uppercased() == wanted }
	}
}

public extension KeyDefinition {
	enum KeyType: Sendable, Hashable {
		/// `blank` is a spacer, not a key: it draws nothing and does nothing. Use it
		/// to hold a row's shoulder open when a host supplies no function key there,
		/// so the letters stay on their usual columns either way.
		case letter, delete, dismiss, tab, enter, space, navigation, pencil, blank, custom(id: String, imageName: String, action: @Sendable () -> Void)
		var imageName: String? {
			switch self {
			case .dismiss: "keyboard.chevron.compact.down"
			case .delete: "delete.left"
			case .tab: "arrow.right.to.line.compact"
			case .enter: "return"
			case .space: "space"
			case .navigation: "arrow.left.arrow.right"
			case .pencil: "pencil"

			case .custom(_, let imageName, _): imageName
			default: nil
			}
		}
		
		public init(file: String = #file, line: Int = #line, column: Int = #column,  imageName: String, action: @Sendable @escaping () -> Void) {
			self = .custom(id: "\(file)\(line)\(column)", imageName: imageName, action: action)
		}
		
		var id: String {
			switch self {
			case .letter: "letter"
			case .delete: "delete"
			case .dismiss: "dismiss"
			case .tab: "tab"
			case .enter: "enter"
			case .space: "space"
			case .navigation: "navigation"
			case .pencil: "pencil"
			case .blank: "blank"
			case .custom(_, let id, _): id
			}
		}
		
		public static func ==(lhs: Self, rhs: Self) -> Bool {
			lhs.id == rhs.id
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
	}
}

let qwerty: [[KeyDefinition]] = [
	[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
	[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
	[ .init(.dismiss), "Z", "X", "C", "V", "B", "N", "M", .init(.delete)  ]
]
