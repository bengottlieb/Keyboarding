//
//  KeySendable.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/15/25.
//

import SwiftUI

public protocol KeySendable { }

public struct PressedKey: CustomStringConvertible {
	public let keyPress: KeyPress?
	public let string: String?
	public let key: KeyEquivalent?
	public let modifiers: EventModifiers
	
	init(keyPress: KeyPress? = nil, string: String? = nil, key: KeyEquivalent? = nil) {
		self.keyPress = keyPress
		self.string = string
		
		if let key { self.key = key }
		else if let keyPress { self.key = keyPress.key }
		else { self.key = nil }
		
		modifiers = keyPress?.modifiers ?? .init(rawValue: 0)
	}
	
	var isBackspace: Bool { key == .delete  }
	var isShifted: Bool { modifiers.contains(.shift) }
	
	public var description: String {
		if modifiers.isEmpty { return keyDescription }
		
		return keyDescription + ", " + modifiersDescription
	}
	
	var modifiersDescription: String {
		if modifiers.isEmpty { return "" }
		return "\(modifiers)"
	}
	
	var keyDescription: String {
		if let key {
			switch key {
			case .upArrow: return "Up arrow"
			case .downArrow: return "Down arrow"
			case .leftArrow: return "Left arrow"
			case .rightArrow: return "Right arrow"
			case .escape: return "Escape"
			case .delete: return "Delete"
			case .deleteForward: return "Delete forward"
			case .home: return "Home"
			case .end: return "End"
			case .pageUp: return "Page up"
			case .pageDown: return "Page down"
			case .clear: return "Clear"
			case .tab: return "Tab"
			case .space: return "Space"
			case .return: return "return"
			default: break
			}
		}
		if let string {
			return "Key(\"\(string)\")"
		}
		return "Empty key"
	}
}


extension KeyPress: KeySendable { }
extension String: KeySendable { }

public enum SpecialPressedKeys: KeySendable {
	case backspace
	
	var pressedKey: PressedKey {
		switch self {
		case .backspace: .init(key: .delete)
		}
	}
}
