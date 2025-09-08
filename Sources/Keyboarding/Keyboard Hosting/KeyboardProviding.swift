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
		context.coordinator.content = content()
		context.coordinator.sendKey = sendKey
		context.coordinator.useSystemKeyboard = useSystemKeyboard
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(keyboard: keyboard, content: content())
	}
}

extension KeyboardProviding {
	@MainActor class Coordinator {
		var controller: UIViewController!
		var keyboardController: UIViewController!
		var container: Container!
		var sendKey: KeySender? { didSet { container.sendKey = sendKey }}
		var useSystemKeyboard: UseSystemKeyboard = .never { didSet { container.useSystemKeyboard = useSystemKeyboard }}
		var content: Content { didSet { contentBinding?.wrappedValue = content }}
		
		var contentBinding: Binding<Content>?
		
		init(keyboard: () -> KeyboardView, content: Content) {
			self.content = content
			controller = UIHostingController(rootView: UpdatingContainer(content: content, setup: { binding in
				self.contentBinding = binding
			}))
			keyboardController = UIHostingController(rootView: keyboard().environment(\.sendKey, .init({ [weak self] key in
				self?.sendKey?(key) ?? .ignored
			})))
			container = .init(host: controller, keyboard: keyboardController)
		}
		
	}
}

struct UpdatingContainer<Content: View>: View {
	@State var content: Content
	var setup: (Binding<Content>) -> Void
	
	var body: some View {
		VStack {
			content
		}
		.onAppear { setup($content) }
	}
}
