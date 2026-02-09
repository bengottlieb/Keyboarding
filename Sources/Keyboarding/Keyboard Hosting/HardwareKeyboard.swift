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
	static public let instance = HardwareKeyboard()

	var cancelBag: Set<AnyCancellable> = []
	@Published public var keyboardIsConnected: Bool

	func setup() { }

	private init() {
		// Initialize on main actor's context
		self.keyboardIsConnected = GCKeyboard.coalesced != nil

		// Handlers run on .main queue. Since we specify queue: .main, we can assume main actor isolation.
		// Using [weak self] as best practice, even for singletons
		NotificationCenter.default.addObserver(forName: Notification.Name.GCKeyboardDidConnect, object: nil, queue: .main) { [weak self] _ in
			guard let self else { return }
			print("⌨ Hardware keyboard connected")

			MainActor.assumeIsolated {
				withAnimation { self.keyboardIsConnected = true }
			}
		}

		NotificationCenter.default.addObserver(forName: Notification.Name.GCKeyboardDidDisconnect, object: nil, queue: .main) { [weak self] _ in
			guard let self else { return }
			print("⌨ Hardware keyboard disconnected")

			MainActor.assumeIsolated {
				withAnimation { self.keyboardIsConnected = false }
			}
		}
	}
}
#else
@MainActor public class HardwareKeyboard: ObservableObject {
	static public let instance = HardwareKeyboard()

	@Published public var keyboardIsConnected = true
}
#endif
