//
//  KeyboardProviding.Container.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/15/25.
//

import SwiftUI
import Combine

extension KeyboardProviding {
	class Container: UIView, UIKeyInput {
		var hasText: Bool { true }
		func insertText(_ text: String) { _ = sendKey?(text) }
		func deleteBackward() { _ = sendKey?(.backspace) }
		var coordinator: Coordinator?
		
		override var canBecomeFirstResponder: Bool { true }

		let host: UIViewController
		let keyboard: UIViewController
		var sendKey: KeySender?
		
		var isHardwareKeyboardConnected: Bool { HardwareKeyboard.instance.keyboardIsConnected }
		
		var useSystemKeyboard: UseSystemKeyboard = .never {
			didSet {
				if !isFirstResponder { return }
				if useSystemKeyboard == oldValue { return }
				switch useSystemKeyboard {
				case .never:
					if !isHardwareKeyboardConnected, oldValue == .ifHardware { return }
					
				case .ifHardware:
					if useSystemKeyboard == .always { return }
					
				case .always:
					if isHardwareKeyboardConnected, oldValue == .ifHardware { return }
				}
				
				_ = resignFirstResponder()
				_ = becomeFirstResponder()
			}}
		
		override func resignFirstResponder() -> Bool {
			coordinator?.wasFocused = false
			return super.resignFirstResponder()
		}
		
		override func becomeFirstResponder() -> Bool {
			coordinator?.wasFocused = true
			return super.becomeFirstResponder()
		}
		override var inputView: UIView? {
			switch useSystemKeyboard {
			case .always: nil
			case .ifHardware:
				isHardwareKeyboardConnected ? nil : keyboard.view
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
