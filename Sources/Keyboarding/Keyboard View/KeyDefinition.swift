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
	
	public var id: String { string ?? type.rawValue }
	
	public init(stringLiteral value: StringLiteralType) {
		string = value
		type = .letter
	}
	
	public init(_ type: KeyType) {
		self.type = type
		string = nil
	}
	
	public init(keyPress: KeyPress) {
		string = keyPress.characters
		switch keyPress.key {
		case .delete, .deleteForward: type = .delete
			
		default: type = .letter
		}
	}
}

public extension KeyDefinition {
	enum KeyType: String, Sendable, Codable, Hashable {
		case letter, delete, dismiss, tab
		var imageName: String? {
			switch self {
			case .dismiss: "keyboard.chevron.compact.down"
			case .delete: "delete.left"
			case .tab: "arrow.right.to.line.compact"
				
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
