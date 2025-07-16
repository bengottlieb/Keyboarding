//
//  KeyDefinition.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/16/25.
//

import SwiftUI

public protocol KeyDefinition: Sendable {
	var string: String? { get set }
	var keycapLabel: String? { get }
	var keycapImage: Image? { get }
	var modifiers: EventModifiers { get }
	var pressedKey: PressedKey { get }
}

public extension KeyDefinition {
	var string: String? {
		get { nil }
		set { }
	}
	var keycapLabel: String? { nil }
	var keycapImage: Image? { nil }
	var modifiers: EventModifiers { [] }
	
	var isShifted: Bool { modifiers.contains(.shift) }
	var pressedKey: PressedKey { PressedKey(string: string) }
}

public extension KeyDefinition {
	var isDismiss: Bool { self is DismissKeyCommand }
}

public struct DismissKeyCommand: KeyDefinition {
	public var keycapImage: Image? { Image(systemName: "keyboard.chevron.compact.down") }
}

public struct PlainKeyCommand: KeyDefinition {
	public var string: String?
	public var keycapLabel: String? { string }
}

extension String: KeyDefinition {
	public var text: String? { self }
	public var keycapLabel: String? { self }
}


