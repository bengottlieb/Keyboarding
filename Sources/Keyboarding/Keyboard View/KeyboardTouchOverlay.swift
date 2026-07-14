//
//  KeyboardTouchOverlay.swift
//  Keyboarding
//
//  Live-touch state and its feedback layer. The model is @Observable and only
//  this overlay reads it, so a finger going down, sliding, or lifting redraws
//  just the bubble and press tint — never the keycaps beneath. KeyboardView's
//  body must not read the model, or every touch re-renders the whole keyboard.
//

import SwiftUI

@Observable @MainActor final class KeyboardTouchModel {
	// One entry per finger currently down, keyed by the key it first touched;
	// the value is the key now under that finger.
	private(set) var targets: [String: KeyDefinition] = [:]
	private(set) var hapticPulse = 0

	func update(origin: KeyDefinition, target: KeyDefinition?) {
		guard targets[origin.id] != target else { return }
		if let target {
			targets[origin.id] = target
			hapticPulse += 1
		} else {
			targets.removeValue(forKey: origin.id)
		}
	}

	func end(origin: KeyDefinition) {
		targets.removeValue(forKey: origin.id)
	}
}

struct KeyboardTouchOverlay: View {
	let touches: KeyboardTouchModel
	let metrics: KeyboardMetrics
	@Environment(\.keyboardStyle) var kbStyle

	var body: some View {
		ZStack(alignment: .topLeading) {
			ForEach(touches.targets.keys.sorted(), id: \.self) { originID in
				if let target = touches.targets[originID], let rect = metrics.rect(for: target) {
					pressTint(over: rect)
					if target.type == .letter, let text = target.string {
						bubble(text, above: rect)
					}
				}
			}
		}
		.sensoryFeedback(trigger: touches.hapticPulse) { _, _ in kbStyle.enableHaptics ? .selection : nil }
		.allowsHitTesting(false)
	}

	// Matches the keycap face (which is inset 2pt within its frame).
	private func pressTint(over rect: CGRect) -> some View {
		RoundedRectangle(cornerRadius: kbStyle.cornerRadius)
			.fill(kbStyle.keyInk.opacity(0.12))
			.frame(width: rect.width - 4, height: rect.height - 4)
			.position(x: rect.midX, y: rect.midY)
	}

	private func bubble(_ text: String, above rect: CGRect) -> some View {
		let width = metrics.keyCapWidth * 1.6
		let height = metrics.keyCapHeight * 1.15
		return KeyPreviewBubble(text: text)
			.font(kbStyle.keyFont.font(size: metrics.keyCapWidth * 0.66))
			.frame(width: width, height: height)
			.position(x: min(max(rect.midX, metrics.bounds.minX + width / 2), metrics.bounds.maxX - width / 2),
			          y: rect.minY - height / 2 - 4)
	}
}
