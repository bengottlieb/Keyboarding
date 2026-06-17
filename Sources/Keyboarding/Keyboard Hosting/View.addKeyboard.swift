import SwiftUI

#if os(iOS)
public extension View {
	@ViewBuilder func addKeyboard<Keyboard: View>(isFocused: Binding<Bool>, useSystemKeyboard: UseSystemKeyboard = .never, _ keyboard: Keyboard, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		KeyboardProviding(isFocused: isFocused, useSystemKeyboard: useSystemKeyboard, keyboard: { keyboard }, content: { self })
			.environment(\.sendKey, .init(handleKeyPress))
			.onKeyPress { handleKeyPress(.init(keyPress: $0)) }
	}

	@ViewBuilder func addKeyboard(isFocused: Binding<Bool>, useSystemKeyboard: UseSystemKeyboard = .never, _ keymap: Keymap, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		KeyboardProviding(isFocused: isFocused, useSystemKeyboard: useSystemKeyboard, keyboard: { KeyboardView(keymap: keymap) }, content: { self })
			.environment(\.sendKey, .init(handleKeyPress))
			.onKeyPress { handleKeyPress(.init(keyPress: $0)) }
	}

	@ViewBuilder func addKeyboard(isFocused: Binding<Bool>, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		KeyboardProviding(isFocused: isFocused, useSystemKeyboard: .always, keyboard: { EmptyView() }, content: { self })
			.environment(\.sendKey, .init(handleKeyPress))
			.onKeyPress { handleKeyPress(.init(keyPress: $0)) }
	}
}
#else
// macOS has no software input-accessory mechanism, so there is nothing to host.
// Keep the same API: wire the key handler and forward hardware key presses.
public extension View {
	@ViewBuilder func addKeyboard<Keyboard: View>(isFocused: Binding<Bool>, useSystemKeyboard: UseSystemKeyboard = .never, _ keyboard: Keyboard, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		environment(\.sendKey, .init(handleKeyPress))
			.onKeyPress { handleKeyPress(.init(keyPress: $0)) }
	}

	@ViewBuilder func addKeyboard(isFocused: Binding<Bool>, useSystemKeyboard: UseSystemKeyboard = .never, _ keymap: Keymap, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		environment(\.sendKey, .init(handleKeyPress))
			.onKeyPress { handleKeyPress(.init(keyPress: $0)) }
	}

	@ViewBuilder func addKeyboard(isFocused: Binding<Bool>, handleKeyPress:  @escaping HandleKeyPress) -> some View {
		environment(\.sendKey, .init(handleKeyPress))
			.onKeyPress { handleKeyPress(.init(keyPress: $0)) }
	}
}
#endif
