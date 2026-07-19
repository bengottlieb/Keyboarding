//
//  GlideTrailView.swift
//  Keyboarding
//
//  The comet trail drawn under the finger during a glide: the most recent stretch
//  of the path, fading from nothing at the tail to solid at the fingertip. Lives
//  in the touch overlay layer, so per-sample redraws never touch the keycaps.
//

import SwiftUI

struct GlideTrailView: View {
	let points: [CGPoint]
	let metrics: KeyboardMetrics
	@Environment(\.keyboardStyle) private var kbStyle

	/// How many trailing samples stay visible; older ones have "evaporated".
	private var visibleSamples: Int { 48 }
	/// Opacity steps from tail to head — drawn as chunked sub-strokes, which reads
	/// as a continuous fade at stroke widths this size.
	private var fadeSteps: Int { 6 }

	var body: some View {
		Canvas { context, _ in
			let tail = Array(points.suffix(visibleSamples))
			guard tail.count > 1 else { return }
			let lineWidth = metrics.keyCapWidth * 0.22
			let chunkSize = max(2, tail.count / fadeSteps)
			var index = 0
			var step = 0
			while index < tail.count - 1 {
				let end = min(index + chunkSize, tail.count - 1)
				var path = Path()
				path.move(to: tail[index])
				for point in tail[(index + 1)...end] { path.addLine(to: point) }
				let progress = Double(step + 1) / Double(fadeSteps)
				context.stroke(path, with: .color(kbStyle.keyInk.opacity(0.45 * progress)),
				               style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
				index = end
				step += 1
			}
		}
		.allowsHitTesting(false)
	}
}
