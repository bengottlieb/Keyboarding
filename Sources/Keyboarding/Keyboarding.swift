import SwiftUI

public extension View {
	@ViewBuilder func addKeyboard<Keyboard: View>(isFocused: Bool, _ keyboard: Keyboard, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		KeyboardProviding(isFocused: isFocused, keyboard: { keyboard }, content: { self })
			.environment(\.sendKey, .init(handleKeyPress))
//		Text("Test")
	}
}
