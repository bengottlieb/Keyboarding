//
//  File.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/13/25.
//

import SwiftUI

struct KeyboardProviding<Content: View, KeyboardView: View>: UIViewRepresentable {
	var content: () -> Content
	var keyboard: () -> KeyboardView
	var isFocused: Bool
	@Environment(\.sendKey) var sendKey
	
	init(isFocused: Bool, @ViewBuilder keyboard: @escaping @MainActor () -> KeyboardView, @ViewBuilder content: @escaping @MainActor () -> Content) {
		self.content = content
		self.keyboard = keyboard
		self.isFocused = isFocused
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
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(keyboard: keyboard, content: content)
	}
}

extension KeyboardProviding {
	class Container: UIView, UIKeyInput {
		var hasText: Bool { true }
		
		func insertText(_ text: String) {
			
		}
		
		func deleteBackward() {
			
		}
		
		let host: UIViewController
		let keyboard: UIViewController
		override var canBecomeFirstResponder: Bool { true }
		
		override var inputView: UIView? { keyboard.view }
		
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
		var sendKey: KeySender?

		init(keyboard: () -> KeyboardView, content: () -> Content) {
			controller = UIHostingController(rootView: content())
			keyboardController = UIHostingController(rootView: keyboard().environment(\.sendKey, .init({ [weak self] key in
				self?.sendKey?(key) ?? .ignored
			})))
			container = .init(host: controller, keyboard: keyboardController)
		}
	}
}
