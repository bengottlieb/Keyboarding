//
//  KeyCap.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/16/25.
//

import SwiftUI

struct KeyCap: View {
	@State private var hapticTrigger = false
//	@Environment(\.keyboardOptions) var keyboardOptions
	let keyCap: KeyDefinition
	@Environment(\.sendKey) var sendKey
	
	var body: some View {
		Button(action: {
			hapticTrigger.toggle()
			sendKey(keyCap.pressedKey)
			//keyboardTarget?.handle(key: keyCap.forTarget(keyboardTarget), options: keyboardOptions, focus: nil)
		}) {
			if let text = keyCap.keycapLabel {
				Text(text)
			} else if let image = keyCap.keycapImage {
				image
			}
		}
		.sensoryFeedback(.selection, trigger: hapticTrigger)
	}
}
