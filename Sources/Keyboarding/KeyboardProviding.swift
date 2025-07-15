//
//  KeyboardProviding.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/13/25.
//

import SwiftUI

struct KeyboardProviding<Content: View, KeyboardView: View>: UIViewRepresentable {
	@ViewBuilder var content: () -> Content
	@ViewBuilder var keyboard: () -> KeyboardView
	var isFocused: Bool
	var useSystemKeyboard: UseSystemKeyboard
	@Environment(\.sendKey) var sendKey
	
	init(isFocused: Bool, useSystemKeyboard: UseSystemKeyboard, @ViewBuilder keyboard: @escaping @MainActor () -> KeyboardView, @ViewBuilder content: @escaping @MainActor () -> Content) {
		self.content = content
		self.keyboard = keyboard
		self.isFocused = isFocused
		self.useSystemKeyboard = useSystemKeyboard
	}

	func makeUIView(context: Context) -> Container {
		context.coordinator.container
	}
	
	func updateUIView(_ uiView: Container, context: Context) {
		if isFocused {
			context.coordinator.container.becomeFirstResponder()
		} else {
			context.coordinator.container.resignFirstResponder()
		}
		context.coordinator.sendKey = sendKey
		context.coordinator.useSystemKeyboard = useSystemKeyboard
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(keyboard: keyboard, content: content)
	}
}

extension KeyboardProviding {
	@MainActor class Coordinator {
		let controller: UIViewController
		var keyboardController: UIViewController!
		var container: Container!
		var sendKey: KeySender? { didSet { container.sendKey = sendKey }}
		var useSystemKeyboard: UseSystemKeyboard = .never { didSet { container.useSystemKeyboard = useSystemKeyboard }}
		
		init(keyboard: () -> KeyboardView, content: () -> Content) {
			controller = UIHostingController(rootView: content())
			keyboardController = UIHostingController(rootView: keyboard().environment(\.sendKey, .init({ [weak self] key in
				self?.sendKey?(key) ?? .ignored
			})))
			container = .init(host: controller, keyboard: keyboardController)
		}
	}
}
