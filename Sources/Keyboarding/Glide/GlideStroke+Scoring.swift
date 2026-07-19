//
//  GlideStroke+Scoring.swift
//  Keyboarding
//
//  Shape matching: how closely does the drawn path resemble the ideal path a
//  candidate word would trace through the key centers? Both paths are resampled
//  to a fixed number of arc-length-uniform points and compared pointwise, with
//  the endpoints weighted extra (users aim the start and end of a glide far more
//  deliberately than the middle). Scores are 0…1, higher is a better match.
//
//  This is deliberately the simplest credible decoder (proportional shape
//  matching, à la SHARK²'s location channel). Known upgrades, in rough order of
//  payoff, if matching ever feels too loose:
//   - Elastic matching (DTW) instead of fixed pointwise comparison, to forgive
//     locally rushed or stretched segments of the drawn path.
//   - Per-key Gaussian likelihoods (score each sample against a distribution
//     centered on the key, not raw distance), which naturally models fat-finger
//     spread and key size.
//   - A separate scale/translation-invariant "shape channel" compared alongside
//     this location channel, to catch sloppy-but-right-shaped glides.
//   - Corner detection to extract high-confidence anchor letters and prune the
//     candidate pool before full scoring.
//   - A language-model re-rank of the top few candidates.
//

import Foundation
import CoreGraphics

public struct GlideMatch: Sendable, Equatable {
	public let word: String
	/// 0…1 shape-match quality; ~0.5 is already a fairly sloppy trace.
	public let score: Double
}

public extension GlideStroke {
	/// Score every candidate against the drawn path, best first. Candidates that
	/// can't be traced on this keyboard (letters with no key) are dropped.
	func matches(for candidates: [String]) -> [GlideMatch] {
		let drawn = Self.resample(points, count: Self.sampleCount)
		guard !drawn.isEmpty else { return [] }
		return candidates
			.compactMap { word in score(word, against: drawn).map { GlideMatch(word: word, score: $0) } }
			.sorted { $0.score > $1.score }
	}

	/// Shape-match a single word against the stroke, or nil if it can't be traced.
	func score(_ word: String) -> Double? {
		let drawn = Self.resample(points, count: Self.sampleCount)
		guard !drawn.isEmpty else { return nil }
		return score(word, against: drawn)
	}

	// MARK: - Internals

	/// Samples per path. Enough to keep mid-word wiggles visible; few enough that
	/// scoring thousands of candidates stays trivially cheap.
	private static var sampleCount: Int { 32 }
	/// Extra weight on the first / last samples of the comparison.
	private static var endpointWeight: Double { 2.5 }
	/// Fraction of samples at each end treated as "endpoint" for weighting.
	private static var endpointFraction: Double { 0.1 }

	private func score(_ word: String, against drawn: [CGPoint]) -> Double? {
		guard let ideal = idealPath(for: word) else { return nil }
		let template = Self.resample(ideal, count: Self.sampleCount)
		guard template.count == drawn.count else { return nil }
		let endpointSamples = max(1, Int(Double(drawn.count) * Self.endpointFraction))
		var total = 0.0, weightSum = 0.0
		for index in drawn.indices {
			let isEndpoint = index < endpointSamples || index >= drawn.count - endpointSamples
			let weight = isEndpoint ? Self.endpointWeight : 1.0
			total += drawn[index].distance(to: template[index]) * weight
			weightSum += weight
		}
		// Normalize by key width so the score is layout-size independent: a mean
		// error of one full key width scores e⁻¹ ≈ 0.37.
		let meanKeyWidths = (total / weightSum) / geometry.keySize.width
		return exp(-meanKeyWidths)
	}

	/// The ideal polyline for a word: key centers of its letters in order, with
	/// consecutive repeats collapsed (a glide can't express double letters — the
	/// host restores them by choosing the full word, not the traced letters).
	/// Public so debug overlays can draw what the scorer compared against.
	func idealPath(for word: String) -> [CGPoint]? {
		var path: [CGPoint] = []
		var previous: Character?
		for character in word.uppercased() {
			if character == previous { continue }
			previous = character
			guard let center = geometry.centers[String(character)] else { return nil }
			path.append(center)
		}
		return path.isEmpty ? nil : path
	}

	/// Resample a polyline to `count` points spaced uniformly along its arc length.
	/// A degenerate (single-point / zero-length) path becomes `count` copies of its
	/// point, which still compares meaningfully against a near-stationary stroke.
	static func resample(_ source: [CGPoint], count: Int) -> [CGPoint] {
		guard let first = source.first else { return [] }
		guard source.count > 1 else { return Array(repeating: first, count: count) }
		let lengths = zip(source, source.dropFirst()).map { $0.distance(to: $1) }
		let total = lengths.reduce(0, +)
		guard total > 0 else { return Array(repeating: first, count: count) }

		var result: [CGPoint] = [first]
		var segment = 0
		var traversed = 0.0
		for step in 1..<count {
			let target = total * Double(step) / Double(count - 1)
			while segment < lengths.count - 1, traversed + lengths[segment] < target {
				traversed += lengths[segment]
				segment += 1
			}
			let within = lengths[segment] > 0 ? (target - traversed) / lengths[segment] : 0
			let start = source[segment], end = source[segment + 1]
			result.append(CGPoint(x: start.x + (end.x - start.x) * within,
			                      y: start.y + (end.y - start.y) * within))
		}
		return result
	}
}

private extension CGPoint {
	func distance(to other: CGPoint) -> Double {
		let dx = x - other.x, dy = y - other.y
		return (dx * dx + dy * dy).squareRoot()
	}
}
