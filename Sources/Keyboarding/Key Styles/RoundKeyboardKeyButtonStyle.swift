//
//  RoundKeyboardKeyButtonStyle.swift
//
//
//  Created by Ben Gottlieb on 12/2/23.
//

import SwiftUI


struct RoundKeyboardKeyButtonStyle: ButtonStyle {
	var isNextKey = false
	var contentPadding = 0.0
	var foregroundColor = Color(UIColor.systemBackground)
	var backgroundColor = Color.primary
	
	func makeBody(configuration: Configuration) -> some View {
		ZStack {
			configuration.label
				.offset(y: configuration.isPressed ? 0 : 2)
				.opacity(0.25)
			configuration.label
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
//		.aspectRatio(1.0, contentMode: .fit)
		.padding(.bottom, 10)
		.padding(.top, 2)
		.background {
			RoundedRectangle(cornerRadius: 6)
				.fill(backgroundColor)
				.padding(2)
		}
		.scaleEffect(configuration.isPressed ? 0.9 : 1)
		.foregroundStyle(foregroundColor.opacity(configuration.isPressed ? 0.7 : 1))
		.padding(contentPadding)
		.contentShape(.rect)
	}
}

extension ButtonStyle where Self == RoundKeyboardKeyButtonStyle {
	static func roundKeyboardKey(isNextKey: Bool, contentPadding: Double = 0) -> Self { RoundKeyboardKeyButtonStyle(isNextKey: isNextKey, contentPadding: contentPadding) }
}
