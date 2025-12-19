//
//  KeyCapView.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/16/25.
//

import Suite

struct KeyCapView: View {
	@State private var hapticTrigger = false
//	@Environment(\.keyboardOptions) var keyboardOptions
	let definition: KeyDefinition
	@Environment(\.sendKey) var sendKey
	
	func processKeyPress() {
		switch definition.type {
		case .dismiss:
			UIView.resignAllFirstResponders()
			
		default:
			_ = sendKey(definition)
		}
	}
	
	var body: some View {
		Button(action: {
			hapticTrigger.toggle()
			processKeyPress()
			//keyboardTarget?.handle(key: keyCap.forTarget(keyboardTarget), options: keyboardOptions, focus: nil)
		}) {
			if let text = definition.string {
				Text(text)
			} else if let image = definition.type.imageName {
				Image(systemName: image)
			}
		}
		.sensoryFeedback(.selection, trigger: hapticTrigger)
	}
}
