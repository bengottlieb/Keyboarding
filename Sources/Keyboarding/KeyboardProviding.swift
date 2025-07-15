//
//  File.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/13/25.
//

import SwiftUI

struct KeyboardProviding<Content: View, KeyboardView: View>: UIViewRepresentable {
	@ViewBuilder var content: () -> Content
	@ViewBuilder var keyboard: () -> KeyboardView
	var isFocused: Bool
	var useSystemKeyboard = false
	@Environment(\.sendKey) var sendKey
	
	init(isFocused: Bool, useSystemKeyboard: Bool, @ViewBuilder keyboard: @escaping @MainActor () -> KeyboardView, @ViewBuilder content: @escaping @MainActor () -> Content) {
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
	class Container: UIView, UIKeyInput {
		var hasText: Bool { true }
		func insertText(_ text: String) { sendKey?(text) }
		func deleteBackward() { sendKey?(.backspace) }
		
		override var canBecomeFirstResponder: Bool { true }

		let host: UIViewController
		let keyboard: UIViewController
		var sendKey: KeySender?
		
		var useSystemKeyboard = false { didSet { if useSystemKeyboard != oldValue, isFirstResponder {
			resignFirstResponder()
			becomeFirstResponder()
		}}}
		override var inputView: UIView? { useSystemKeyboard ? nil : keyboard.view }
		
		init(host: UIViewController, keyboard: UIViewController) {
			self.host = host
			self.keyboard = keyboard
			super.init(frame: .zero)
			
			addSubview(host.view)

			host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			keyboard.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		}

		required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	}
	
	@MainActor class Coordinator {
		let controller: UIViewController
		var keyboardController: UIViewController!
		var container: Container!
		var sendKey: KeySender? { didSet { container.sendKey = sendKey }}
		var useSystemKeyboard = false { didSet { container.useSystemKeyboard = useSystemKeyboard }}
		
		init(keyboard: () -> KeyboardView, content: () -> Content) {
			controller = UIHostingController(rootView: content())
			keyboardController = useSystemKeyboard ? nil : UIHostingController(rootView: keyboard().environment(\.sendKey, .init({ [weak self] key in
				self?.sendKey?(key) ?? .ignored
			})))
			container = .init(host: controller, keyboard: keyboardController)
		}
	}
}
