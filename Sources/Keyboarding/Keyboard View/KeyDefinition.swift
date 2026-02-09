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
	
	public var id: String { string ?? type.id }
	
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
}

public extension KeyDefinition {
	enum KeyType: Sendable, Hashable {
		case letter, delete, dismiss, tab, enter, space, navigation, custom(id: String, imageName: String, action: @Sendable () -> Void)
		var imageName: String? {
			switch self {
			case .dismiss: "keyboard.chevron.compact.down"
			case .delete: "delete.left"
			case .tab: "arrow.right.to.line.compact"
			case .enter: "return"
			case .space: "space"
			case .navigation: "arrow.left.arrow.right"

			case .custom(let _, let imageName, let _): imageName
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
