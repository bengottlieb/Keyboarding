//
//  SendKey.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/14/25.
//

import SwiftUI

public typealias HandleKeyPress = (KeyDefinition) -> KeyPress.Result

public struct KeySender: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let send: (KeyDefinition) -> KeyPress.Result
	public func callAsFunction(_ key: KeyDefinition) -> KeyPress.Result {
		send(key)
	}

	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}
	
	public init(_ action: @escaping (KeyDefinition) -> KeyPress.Result, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.send = action
	}
	
//	public init(_ action: @escaping HandleKeyPress, file: String = #file, line: Int = #line) {
//		self.line = line
//		self.file = file
//		self.send = { keyPress in
//			if let key = keyPress as? KeyPress { return action(PressedKey(keyPress: key, string: key.characters)) }
//			if let string = keyPress as? String { return action(PressedKey(string: string)) }
//			if let special = keyPress as? SpecialPressedKeys { return action(special.pressedKey)}
//			if let raw = keyPress as? PressedKey { return action(raw)}
//			return .ignored
//		}
//	}

	nonisolated init() {
		self.line = 0
		self.file = ""
		self.send = { keyPress in
			print("Default handling of \(keyPress), ignored.")
			return .ignored
		}
	}

	nonisolated public static let empty = KeySender()
}

extension EnvironmentValues {
	@Entry public var sendKey: KeySender = .empty
}
