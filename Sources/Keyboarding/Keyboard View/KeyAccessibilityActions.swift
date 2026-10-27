//
//  KeyAccessibilityActions.swift
//  Keyboarding
//
//  A key's VoiceOver custom actions — its alternates — attached only when it
//  has some. An empty `.accessibilityActions` still marks the element as having
//  custom actions, so VoiceOver said "Actions available" on every plain key and
//  then listed nothing on a swipe. The key's identity is unchanged either way:
//  the branch lives inside the modifier, not around the key.
//

import SwiftUI

struct KeyAccessibilityActions: ViewModifier {
	let choices: [String]
	let perform: (String) -> Void

	/// Whether the key gets custom actions at all.
	var attachesActions: Bool { !choices.isEmpty }

	func body(content: Content) -> some View {
		if attachesActions {
			content.accessibilityActions {
				ForEach(choices, id: \.self) { choice in
					Button(choice) { perform(choice) }
				}
			}
		} else {
			content
		}
	}
}
