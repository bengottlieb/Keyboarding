//
//  KeySendable.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/15/25.
//

import SwiftUI

public protocol KeySendable { }

public struct PressedKey {
	public internal(set) var keyPress: KeyPress?
	public internal(set) var string: String?
	public internal(set) var isBackspace = false
}


extension KeyPress: KeySendable { }
extension String: KeySendable { }

public enum SpecialPressedKeys: KeySendable {
	case backspace
	
	var pressedKey: PressedKey {
		switch self {
		case .backspace: .init(isBackspace: true)
		}
	}
}
