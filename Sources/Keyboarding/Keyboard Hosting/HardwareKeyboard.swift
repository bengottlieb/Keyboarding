//
//  HardwareKeyboard.swift
//  Keyboarding
//
//  Created by Ben Gottlieb on 7/15/25.
//

import SwiftUI
import Combine
#if os(iOS)
import GameKit

@MainActor public class HardwareKeyboard: ObservableObject {
	static public var instance = HardwareKeyboard()
	
	var cancelBag: Set<AnyCancellable> = []
	@Published public var keyboardIsConnected = GCKeyboard.coalesced != nil
	
	func setup() { }
	
	private init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.GCKeyboardDidConnect, object: nil, queue: .main) { _ in
			print("⌨ Hardware keyboard connected")
			Task { @MainActor in  withAnimation { self.keyboardIsConnected = true } }
		}

		NotificationCenter.default.addObserver(forName: Notification.Name.GCKeyboardDidDisconnect, object: nil, queue: .main) { _ in
			print("⌨ Hardware keyboard disconnected")
			Task { @MainActor in  withAnimation { self.keyboardIsConnected = false } }
		}
	}
}
#else
@MainActor public class HardwareKeyboard: ObservableObject {
	static public var instance = HardwareKeyboard()
	
	@Published public var keyboardIsConnected = true
}
#endif
