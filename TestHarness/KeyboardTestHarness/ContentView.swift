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
    var body: some View {
		 VStack {
			 Button("Toggle Focus") { isFocused.toggle() }
		 }
		 .addKeyboard(isFocused: isFocused, Keyboard()) { key in
			 
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
		}
	}
}

#Preview {
    ContentView()
}
