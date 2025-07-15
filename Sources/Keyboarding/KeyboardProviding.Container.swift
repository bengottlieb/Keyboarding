//
//  KeyboardProviding.Container.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/15/25.
//

import SwiftUI

extension KeyboardProviding {
	class Container: UIView, UIKeyInput {
		var hasText: Bool { true }
		func insertText(_ text: String) { sendKey?(text) }
		func deleteBackward() { sendKey?(.backspace) }
		
		override var canBecomeFirstResponder: Bool { true }

		let host: UIViewController
		let keyboard: UIViewController
		var sendKey: KeySender?
		
		var isHardwareKeyboardConnected: Bool { HardwareKeyboard.instance.keyboardIsConnected }
		
		var useSystemKeyboard: UseSystemKeyboard = .never {
			didSet {
				if !isFirstResponder { return }
				switch useSystemKeyboard {
				case .never:
					if !isHardwareKeyboardConnected, oldValue == .ifHardware { return }
					
				case .ifHardware:
					if useSystemKeyboard == .always { return }
					
				case .always:
					if isHardwareKeyboardConnected, oldValue == .ifHardware { return }
				}
				
				resignFirstResponder()
				becomeFirstResponder()
			}}
		override var inputView: UIView? {
			switch useSystemKeyboard {
			case .always: nil
			case .ifHardware:
				isHardwareKeyboardConnected ? nil : keyboard.view
			case .never:
				keyboard.view
			}
		}
		
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
	

}
