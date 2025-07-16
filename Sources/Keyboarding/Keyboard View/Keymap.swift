//
//  Keymap.swift
//  
//
//  Created by Ben Gottlieb on 8/15/23.
//

import SwiftUI

public typealias KeyDown = @Sendable (KeyCommand) -> Void

public struct Keymap: Sendable {
	public var rows: [[KeyCommand]]
	public init(rows: [[KeyCommand]]) {
		self.rows = rows.map { row in
			row.map { key in 
				if let text = key as? String {
					PlainKeyCommand(text: text)
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
		[ "Z", "X", "C", "V", "B", "N", "M", DeleteKeyCommand() ]
	])
	
	@MainActor public static var qwertyWithDismiss = Keymap(rows: [
		[ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
		[ "A", "S", "D", "F", "G", "H", "J", "K", "L" ],
		[ DismissKeyCommand(), "Z", "X", "C", "V", "B", "N", "M", DeleteKeyCommand() ]
	])
}

public protocol KeyCommand: Sendable { 
	var text: String? { get set }
	var keycapLabel: String? { get }
	var keycapImage: Image? { get }
	var modifiers: EventModifiers { get }
}

public extension KeyCommand {
	var text: String? {
		get { nil }
		set { }
	}
	var keycapLabel: String? { nil }
	var keycapImage: Image? { nil }
	var modifiers: EventModifiers { [] }
	
	var isShifted: Bool { modifiers.contains(.shift) }
}

public extension KeyCommand {
	var isDelete: Bool { self is DeleteKeyCommand }
	var isReturn: Bool { self is ReturnKeyCommand }
	var isSpace: Bool { self is SpaceBarKeyCommand }
	var isDismiss: Bool { self is DismissKeyCommand }
}

public struct DeleteKeyCommand: KeyCommand {
	public var keycapImage: Image? { Image(systemName: "delete.left") }
}

public struct ReturnKeyCommand: KeyCommand {
	public var keycapImage: Image? { Image(systemName: "return") }
}

public struct SpaceBarKeyCommand: KeyCommand {
	public var keycapImage: Image? { Image(systemName: "space") }
}

//public struct ArrowKeyCommand: KeyCommand {
//	public var direction: PZLDirection
//	public var modifiers: EventModifiers = []
//
//	var imageName: String {
//		switch direction {
//		case .horizontal: "arrow.right"
//		case .horizontalReversed: "arrow.left"
//		case .vertical: "arrow.down"
//		case .verticalReversed: "arrow.up"
//		default: ""
//		}
//	}
//	public var keycapImage: Image? { Image(systemName: imageName) }
//}

public struct DismissKeyCommand: KeyCommand {
	public var keycapImage: Image? { Image(systemName: "keyboard.chevron.compact.down") }
}

public struct TabKeyCommand: KeyCommand {
	public var modifiers: EventModifiers = []
	public var keycapImage: Image? { Image(systemName: "arrow.right.to.line.compact") }
}

public struct PlainKeyCommand: KeyCommand {
	public var text: String?
	public var keycapLabel: String? { text }
}

extension String: KeyCommand {
	public var text: String? { self }
	public var keycapLabel: String? { self }
}



