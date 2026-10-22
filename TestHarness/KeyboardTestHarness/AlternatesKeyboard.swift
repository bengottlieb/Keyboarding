//
//  AlternatesKeyboard.swift
//  KeyboardTestHarness
//
//  An inline keyboard with alternates installed: hold A, E or O for a row of
//  accents; any other letter offers the digits. Inline rather than the input
//  view, whose separate hosting controller doesn't see this environment.
//

import SwiftUI
import Keyboarding

struct AlternatesKeyboard: View {
	@Binding var text: String

	var body: some View {
		KeyboardView()
			.environment(\.sendKey, KeySender { key in
				if let string = key.string { text += string } else if key.type == .delete { text = String(text.dropLast()) }
				return .handled
			})
			.environment(\.keyAlternates, KeyAlternatesProvider { key in
				switch key.string {
				case "A": ["A", "À", "Á", "Â", "Ä", "Æ", "Ã", "Å"]
				case "E": ["E", "È", "É", "Ê", "Ë"]
				case "O": ["O", "Ô", "Ö", "Ò", "Ó", "Õ", "Œ", "Ø"]
				default: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
				}
			})
	}
}
