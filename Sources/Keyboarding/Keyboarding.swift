import SwiftUI

public extension View {
	@ViewBuilder func addKeyboard<Keyboard: View>(isFocused: Bool, useSystemKeyboard: UseSystemKeyboard = .never, _ keyboard: Keyboard, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		KeyboardProviding(isFocused: isFocused, useSystemKeyboard: useSystemKeyboard, keyboard: { keyboard }, content: { self })
			.environment(\.sendKey, .init(handleKeyPress))
			.onKeyPress { press in
				print(press)
				return .handled
			}
	}
	
	@ViewBuilder func addKeyboard(isFocused: Bool, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		KeyboardProviding(isFocused: isFocused, useSystemKeyboard: .always, keyboard: { EmptyView() }, content: { self })
			.environment(\.sendKey, .init(handleKeyPress))
	}
}
