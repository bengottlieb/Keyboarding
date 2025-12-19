//
//  ContentView.swift
//  KeyboardTestHarness
//
//  Created by Ben Gottlieb on 7/14/25.
//

import Suite
import Keyboarding

struct ContentView: View {
	@State private var isFocused = false
	@State private var useSystemKeyboard: UseSystemKeyboard = .never
	@State var text = ""
	
	var body: some View {
		 VStack {
			 TextField("Text Field", text: $text)
			 Text(text)
			 LabeledContent {
				 Picker("System Keyboard", selection: $useSystemKeyboard) {
					 Text("Always").tag(UseSystemKeyboard.always)
					 Text("If Hardware").tag(UseSystemKeyboard.ifHardware)
					 Text("Never").tag(UseSystemKeyboard.never)
				 }
				 .pickerStyle(.segmented)
				 .labelsHidden()
			 } label: {
				 Text("System Keyboard")
			 }

			 Text(isFocused ? "Focused" : "Not Focused")
			 Button("Toggle Focus") { isFocused.toggle() }
		 }
		 .addKeyboard(isFocused: $isFocused, useSystemKeyboard: useSystemKeyboard, .qwertyWithDismiss) { key in
			 print("Got key: \(key)")
			 if let string = key.string {
				 text += string
			 } else if key.type == .delete {
				 text = String(text.dropLast())
			 }
			 return .ignored
		 }
        .padding()
		  .overlay(Color.red.opacity(0.3).allowsHitTesting(false))
    }
}

struct Keyboard: View {
	@Environment(\.sendKey) var sendKey
	
	var body: some View {
		HStack {
			Button("A") { _ = sendKey("A") }
			Button("B") { _ = sendKey("B") }
			Button(action: { _ = sendKey(.init(.delete)) }) { Image(systemName: "delete.left") }
		}
	}
}

#Preview {
    ContentView()
}
