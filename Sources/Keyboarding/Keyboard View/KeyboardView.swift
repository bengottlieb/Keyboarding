//
//  KeyboardView.swift
//
//
//  Created by Ben Gottlieb on 8/15/23.
//

import SwiftUI

#if os(iOS)

extension EnvironmentValues {
//	@Entry var keyboardOptions: PZLKeyboardEntryOptions = .default
}

public struct KeyboardView: View {
	var keymap: Keymap = .qwertyWithDismiss
	public var id: String { "\(keymap)" }
//	private var assistant = KeyboardAssistant.instance
//	var hardwareKeyboard = HardwareKeyboard.instance

	public init(keymap: Keymap? = nil) {
		self.keymap = keymap ?? .qwertyWithDismiss
	}
	
	var keyboardHorizontalMargins: CGFloat { 8 }
	
	var keyCapHeight: CGFloat {
		if UIDevice.current.orientation.isLandscape {
			44
		} else {
			54//min(keyCapWidth, 54)
		}
	}
	
	public var body: some View {
		GeometryReader { geo in
			ZStack(alignment: .topLeading) {
				let width = geo.size.width - keyboardHorizontalMargins * 2
				let keyCapWidth = width / CGFloat(keymap.widestRow)
				let rowWidth = width
				Rectangle()
					.fill(.clear)
					.frame(height: keyCapHeight * CGFloat(keymap.rows.count) + 24)
				
								ForEach(keymap.rows.indices, id: \.self) { y in
									let row = keymap.rows[y]
									let rowLeadingMargin = keyboardHorizontalMargins + (rowWidth - CGFloat(row.count) * keyCapWidth) / 2
				
									ForEach(row.indices, id: \.self) { x in
										let action = row[x]
										let isNext = false//assistant.nextKey != nil && action.keycapLabel == assistant.nextKey
										let currentPadding =  0.0//isNext ? 30.0 : 0
										let keyWidth = keyCapWidth + currentPadding
										let keyHeight = keyCapHeight// + currentPadding
										KeyCap(keyCap: action)
											.buttonStyle(.roundKeyboardKey(isNextKey: isNext, contentPadding: currentPadding / 2))
											.frame(width: keyWidth, height: keyHeight)
											.font(.system(size: keyCapWidth * 0.5, weight: .bold, design: .rounded))
											.zIndex(isNext ? 100 : 0)
											.offset(x: rowLeadingMargin + CGFloat(x) * keyCapWidth - currentPadding / 2, y: CGFloat(y) * keyCapHeight - currentPadding / 2)
									}
								}
//								.offset(x: safeFrame.x)
			}
			.padding(.top, 12)
			.ignoresSafeArea(edges: .leading)

			//			.background {
			//				LinearGradient([.keyboardGradientStart, .keyboardGradientEnd], from: .top, to: .bottom)
			//					.ignoresSafeArea()
			//			}
		}
		.frame(width: 400, height: 186)
	}
}


struct KeycapSizePreferenceKey: PreferenceKey {
	nonisolated(unsafe) static var defaultValue: CGSize?
	
	static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
		guard let inValue = value else {
			value = nextValue()
			return
		}
		
		if let next = nextValue() {
			value = CGSize(width: min(next.width, inValue.width), height: min(next.height, inValue.height))
		}
	}
}



#Preview {
	GeometryReader { geo in
		VStack {
			Spacer()
			KeyboardView()
		}
	}
}
#endif

#if os(macOS)
public struct KeyboardView: View {
	public init(width: Double) { }
	
	public init(keymap: Keymap? = nil, safeFrame: CGRect) {
		
	}

	public var body: some View {
		EmptyView()
	}
}
#endif
