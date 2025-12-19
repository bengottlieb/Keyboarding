//
//  KeyboardProviding.Container.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/15/25.
//

import Suite
import Combine

@MainActor extension Gestalt {
	public static var isHardwareKeyboardConnected: Bool { HardwareKeyboard.instance.keyboardIsConnected }
}

extension KeyboardProviding {
	class Container: UIView, UIKeyInput {
		var hasText: Bool { true }
		func insertText(_ text: String) { _ = sendKey?(KeyDefinition(stringLiteral: text)) }
		func deleteBackward() { _ = sendKey?(.init(.delete)) }
		var coordinator: Coordinator?
		var isCyclingFirstRespond = false
		
		override var canBecomeFirstResponder: Bool { true }

		let host: UIViewController
		let keyboard: UIViewController
		var sendKey: KeySender?
				
		var useSystemKeyboard: UseSystemKeyboard = .never {
			didSet {
				if !isFirstResponder { return }
				if useSystemKeyboard == oldValue { return }
				switch useSystemKeyboard {
				case .never:
					if !Gestalt.isHardwareKeyboardConnected, oldValue == .ifHardware { return }
					
				case .ifHardware:
					if useSystemKeyboard == .always { return }
					
				case .always:
					if Gestalt.isHardwareKeyboardConnected, oldValue == .ifHardware { return }
				}
				
				isCyclingFirstRespond = true
				_ = resignFirstResponder()
				_ = becomeFirstResponder()
				isCyclingFirstRespond = false
			}}
		
		override func resignFirstResponder() -> Bool {
			if !isCyclingFirstRespond, !UIView.isResigningFirstResponderOnAll { coordinator?.keyboardVisibilityChanged(to: false) }
			return super.resignFirstResponder()
		}
		
		override func becomeFirstResponder() -> Bool {
			if UIView.isResigningFirstResponderOnAll { return false }
			if !isCyclingFirstRespond { coordinator?.keyboardVisibilityChanged(to: true) }
			return super.becomeFirstResponder()
		}
		
		override var inputView: UIView? {
			switch useSystemKeyboard {
			case .always: nil
			case .ifHardware:
				Gestalt.isHardwareKeyboardConnected ? nil : keyboard.view
			case .never:
				keyboard.view
			}
		}
		
		var keyboardChangeCancellable: AnyCancellable?
		init(host: UIViewController, keyboard: UIViewController) {
			self.host = host
			self.keyboard = keyboard
			super.init(frame: .zero)
			
			addSubview(host.view)

			host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			keyboard.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			keyboardChangeCancellable = HardwareKeyboard.instance.objectWillChange.sink { [weak self] _ in
				guard let self else { return }
				if useSystemKeyboard == .ifHardware, isFirstResponder {
					Task {
//						resignFirstResponder()
//						try? await Task.sleep(for: .seconds(0.2))
//						becomeFirstResponder()
					}
				}
			}
		}

		required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	}
	

}
