//
//  GlideStroke.swift
//  Keyboarding
//
//  A completed glide gesture: the sampled finger path plus a snapshot of the
//  letter-key geometry it was drawn over. The stroke knows nothing about words
//  or dictionaries — the host supplies candidate strings and asks the stroke
//  how well each one matches (see GlideStroke+Scoring).
//

import Foundation
import CoreGraphics

public struct GlideStroke: Sendable {
	/// Finger samples in keyboard space, in order.
	public let points: [CGPoint]
	/// Uppercased letters of the keys traversed, consecutive duplicates collapsed.
	public let tracedLetters: [String]
	let geometry: GlideGeometry

	init(points: [CGPoint], tracedLetters: [String], geometry: GlideGeometry) {
		self.points = points
		self.tracedLetters = tracedLetters
		self.geometry = geometry
	}

	/// Letters whose keys are at or adjacent to where the stroke started. Hosts can
	/// prefilter candidates to those beginning with one of these — users are most
	/// deliberate about the first letter, and it collapses the candidate pool.
	public var startLetters: Set<String> {
		points.first.map { geometry.letters(near: $0) } ?? []
	}

	/// Letters at or adjacent to where the stroke ended (see `startLetters`).
	public var endLetters: Set<String> {
		points.last.map { geometry.letters(near: $0) } ?? []
	}

	/// The captured keyboard's key size, for callers drawing over the stroke.
	public var keySize: CGSize { geometry.keySize }
}

/// Where each letter key's center sat when the stroke was captured, in the same
/// coordinate space as the stroke's points.
struct GlideGeometry: Sendable {
	let centers: [String: CGPoint]
	let keySize: CGSize

	init(centers: [String: CGPoint], keySize: CGSize) {
		self.centers = centers
		self.keySize = keySize
	}

	init(keymap: Keymap, metrics: KeyboardMetrics) {
		var centers: [String: CGPoint] = [:]
		for (y, row) in keymap.rows.enumerated() {
			for (x, key) in row.enumerated() where key.type == .letter {
				guard let letter = key.string?.uppercased() else { continue }
				let rect = metrics.rect(forColumn: x, row: y)
				centers[letter] = CGPoint(x: rect.midX, y: rect.midY)
			}
		}
		self.centers = centers
		self.keySize = CGSize(width: metrics.keyCapWidth, height: metrics.keyCapHeight)
	}

	/// The letters whose key centers lie within roughly one key of the point:
	/// the key under the point plus its immediate neighbors.
	func letters(near point: CGPoint) -> Set<String> {
		var result: Set<String> = []
		for (letter, center) in centers {
			if abs(center.x - point.x) <= keySize.width && abs(center.y - point.y) <= keySize.height {
				result.insert(letter)
			}
		}
		return result
	}
}

public extension GlideStroke {
	/// Test/tooling entry point: build a stroke over an explicit letter layout
	/// without rendering a keyboard.
	static func stroke(points: [CGPoint], tracedLetters: [String], letterCenters: [String: CGPoint], keySize: CGSize) -> GlideStroke {
		GlideStroke(points: points, tracedLetters: tracedLetters,
		            geometry: GlideGeometry(centers: letterCenters, keySize: keySize))
	}
}
