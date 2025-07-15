//
//  SendKey.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/14/25.
//

import SwiftUI

public typealias HandleKeyPress = (PressedKey) -> KeyPress.Result

public struct PressedKey {
	let keyPress: KeyPress?
	let string: String?
}

public protocol KeySendable { }

extension KeyPress: KeySendable { }
extension String: KeySendable { }

public struct KeySender: Equatable, @unchecked Sendable {
	let line: Int
	let file: String
	let send: (KeySendable) -> KeyPress.Result
	public func callAsFunction(_ key: KeySendable) -> KeyPress.Result {
		send(key)
	}
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file
	}
	
	public init(_ action: @escaping (KeySendable) -> KeyPress.Result, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.send = action
	}
	
	public init(_ action: @escaping HandleKeyPress, file: String = #file, line: Int = #line) {
		self.line = line
		self.file = file
		self.send = { keyPress in
			if let key = keyPress as? KeyPress { return action(.init(keyPress: key, string: key.characters)) }
			if let string = keyPress as? String { return action(.init(keyPress: nil, string: string)) }

			return .ignored
		}
	}

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
