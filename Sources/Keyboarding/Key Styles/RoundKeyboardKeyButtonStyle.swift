//
//  RoundKeyboardKeyButtonStyle.swift
//
//
//  Created by Ben Gottlieb on 12/2/23.
//

import SwiftUI


struct RoundKeyboardKeyButtonStyle: ButtonStyle {
	var faceColor: Color = Color.gray.opacity(0.22)
	var inkColor: Color = .primary
	var cornerRadius: CGFloat = 6
	var isNextKey = false
	var contentPadding = 0.0

	func makeBody(configuration: Configuration) -> some View {
		ZStack {
			configuration.label
				.offset(y: configuration.isPressed ? 0 : 2)
				.opacity(0.25)
			configuration.label
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(.bottom, 10)
		.padding(.top, 2)
		.background {
			RoundedRectangle(cornerRadius: cornerRadius)
				.fill(faceColor)
				.padding(2)
		}
		.scaleEffect(configuration.isPressed ? 0.9 : 1)
		.foregroundStyle(inkColor.opacity(configuration.isPressed ? 0.7 : 1))
		.padding(contentPadding)
		.contentShape(.rect)
	}
}

extension ButtonStyle where Self == RoundKeyboardKeyButtonStyle {
	static func roundKeyboardKey(faceColor: Color, inkColor: Color, cornerRadius: CGFloat,
	                             isNextKey: Bool = false, contentPadding: Double = 0) -> Self {
		RoundKeyboardKeyButtonStyle(faceColor: faceColor, inkColor: inkColor, cornerRadius: cornerRadius,
		                            isNextKey: isNextKey, contentPadding: contentPadding)
	}
}
