import SwiftUI

public typealias HandleKeyPress = (KeyPress) -> KeyPress.Result

public extension View {
	@ViewBuilder func addKeyboard<Keyboard: View>(isFocused: Bool, _ keyboard: Keyboard, handleKeyPress:  HandleKeyPress? = nil) -> some View {
		KeyboardProviding(isFocused: isFocused, keyboard: { keyboard }, content: { self })
//		Text("Test")
	}
}
