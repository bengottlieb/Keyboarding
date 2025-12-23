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
	
	public var id: String { string ?? type.rawValue }
	
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
		string = keyPress.characters
		self.keyPress = keyPress
		switch keyPress.key {
		case .delete, .deleteForward: type = .delete
			
		default: type = .letter
		}
	}
	
	public var isShifted: Bool {
		guard let keyPress else { return false }
		return keyPress.modifiers.contains(.shift)
	}
}

public extension KeyDefinition {
	enum KeyType: String, Sendable, Codable, Hashable {
		case letter, delete, dismiss, tab, enter, space
		var imageName: String? {
			switch self {
			case .dismiss: "keyboard.chevron.compact.down"
			case .delete: "delete.left"
			case .tab: "arrow.right.to.line.compact"
			case .enter: "return"
			case .space: "space"

			default: nil
			}
		}
	}
}

let qwerty: [[KeyDefinition]] = [
	[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
	[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
	[ .init(.dismiss), "Z", "X", "C", "V", "B", "N", "M", .init(.delete)  ]
]
