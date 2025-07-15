//
//  ContentView.swift
//  KeyboardTestHarness
//
//  Created by Ben Gottlieb on 7/14/25.
//

import SwiftUI
import Keyboarding

struct ContentView: View {
	@State private var isFocused = false
	@State private var useSystemKeyboard: UseSystemKeyboard = .never

	var body: some View {
		 VStack {
			 Picker("System Keyboard", selection: $useSystemKeyboard) {
				 Text("Always").tag(UseSystemKeyboard.always)
				 Text("If Hardware").tag(UseSystemKeyboard.ifHardware)
				 Text("Never").tag(UseSystemKeyboard.never)
			 }
			 .pickerStyle(.segmented)
			 Button("Toggle Focus") { isFocused.toggle() }
		 }
		 .addKeyboard(isFocused: isFocused, useSystemKeyboard: useSystemKeyboard, Keyboard()) { key in
			 print("Key: \(key)")
			 return .ignored
		 }
        .padding()
    }
}

struct Keyboard: View {
	@Environment(\.sendKey) var sendKey
	
	var body: some View {
		HStack {
			Button("A") { _ = sendKey("A") }
			Button("B") { _ = sendKey("B") }
			Button(action: { _ = sendKey(.backspace) }) { Image(systemName: "delete.left") }
		}
	}
}

#Preview {
    ContentView()
}
