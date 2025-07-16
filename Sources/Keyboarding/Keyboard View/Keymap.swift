//
//  Keymap.swift
//  
//
//  Created by Ben Gottlieb on 8/15/23.
//

import SwiftUI

public struct Keymap: Sendable {
	public var rows: [[KeyDefinition]]
	public init(rows: [[KeyDefinition]]) {
		self.rows = rows.map { row in
			row.map { key in 
				if let text = key as? String {
					PlainKeyCommand(string: text)
				} else {
					key
				}
			}
		}
	}
	public var widestRow: Int {
		rows.map { $0.count }.max() ?? 0
	}
}

extension Keymap {
	@MainActor public static var qwerty = Keymap(rows: [
		[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
		[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
		[ "Z", "X", "C", "V", "B", "N", "M", PressedKey(key: .delete) ]
	])
	
	@MainActor public static var qwertyWithDismiss = Keymap(rows: [
		[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
		[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
		[ DismissKeyCommand(), "Z", "X", "C", "V", "B", "N", "M", PressedKey(key: .delete) ]
	])
}

extension PressedKey: KeyDefinition {
	public var keycapImage: Image? {
		if key == .delete { return Image(systemName: "delete.left") }
		if key == .return { return Image(systemName: "return") }
		if key == .tab { return Image(systemName: "arrow.right.to.line.compact") }
		return nil
	}
	
	public var pressedKey: PressedKey { self }
}


