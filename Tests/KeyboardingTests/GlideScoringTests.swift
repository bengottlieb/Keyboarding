//
//  GlideScoringTests.swift
//  KeyboardingTests
//
//  The scorer's job is judgment: given a drawn path, the word the user meant must
//  outrank plausible same-length rivals — that's the behavior the solver UI
//  depends on, not any particular score value.
//

import Testing
import CoreGraphics
@testable import Keyboarding

/// A synthetic QWERTY layout with 40×54 keys, matching the real keyboard's shape
/// so traces exercise realistic geometry.
private enum TestKeyboard {
	static let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
	static let keySize = CGSize(width: 40, height: 54)

	static var centers: [String: CGPoint] {
		var result: [String: CGPoint] = [:]
		for (y, row) in rows.enumerated() {
			let leading = (CGFloat(rows[0].count - row.count) * keySize.width) / 2
			for (x, letter) in row.enumerated() {
				result[String(letter)] = CGPoint(x: leading + (CGFloat(x) + 0.5) * keySize.width,
				                                 y: (CGFloat(y) + 0.5) * keySize.height)
			}
		}
		return result
	}

	/// A stroke that traces straight lines through the given letters' key centers,
	/// sampled densely like a real drag.
	static func trace(_ letters: String) -> GlideStroke {
		let centers = centers
		let anchors = letters.map { centers[String($0)]! }
		var points: [CGPoint] = []
		for (start, end) in zip(anchors, anchors.dropFirst()) {
			for step in 0..<12 {
				let t = CGFloat(step) / 12
				points.append(CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t))
			}
		}
		points.append(anchors.last!)
		var traced: [String] = []
		for letter in letters.uppercased() where traced.last != String(letter) { traced.append(String(letter)) }
		return .stroke(points: points, tracedLetters: traced, letterCenters: centers, keySize: keySize)
	}
}

struct GlideScoringTests {
	@Test func perfectTraceBeatsRivals() {
		let stroke = TestKeyboard.trace("WHALE")
		let matches = stroke.matches(for: ["WHALE", "WHEEL", "SHALE", "CRANE"])
		#expect(matches.first?.word == "WHALE")
		#expect(matches.first!.score > 0.9)
	}

	@Test func matchesAreSortedBestFirst() {
		let matches = TestKeyboard.trace("STONE").matches(for: ["STONE", "SPINE", "SCONE"])
		let scores = matches.map(\.score)
		#expect(scores == scores.sorted(by: >))
	}

	/// Double letters can't be expressed in a glide: the trace H-E-L-O must still
	/// score HELLO essentially as well as HELO, or every double-letter word loses.
	@Test func doubleLettersCollapse() {
		let stroke = TestKeyboard.trace("HELO")
		let hello = stroke.score("HELLO")!
		#expect(hello > 0.9)
	}

	/// A word containing a character with no key (hyphens, digits) can't be traced
	/// and must drop out rather than crash or score garbage.
	@Test func untraceableCandidatesAreDropped() {
		let matches = TestKeyboard.trace("CAT").matches(for: ["CAT", "A-1"])
		#expect(matches.map(\.word) == ["CAT"])
	}

	/// The letters lying on a straight segment (no corner) must not sink the word:
	/// C→T passes right through nothing near A, but CAT's ideal path IS C→A→T, so
	/// tracing C→A→T straight must keep CAT ahead of a word whose shape differs.
	@Test func midlineLettersScoreWell() {
		let stroke = TestKeyboard.trace("CAT")
		let matches = stroke.matches(for: ["CAT", "COT", "CUT"])
		#expect(matches.first?.word == "CAT")
	}

	/// Start/end letters are what users aim deliberately, so a trace sharing shape
	/// but ending elsewhere must lose: BOAT vs BOAR differ only in the last key.
	@Test func endpointsDominate() {
		let stroke = TestKeyboard.trace("BOAT")
		#expect(stroke.score("BOAT")! > stroke.score("BOAR")!)
	}

	@Test func neighborLettersSurfaceAtEndpoints() {
		let stroke = TestKeyboard.trace("DOG")
		#expect(stroke.startLetters.contains("D"))
		#expect(stroke.startLetters.contains("S"))   // neighbor of D
		#expect(stroke.endLetters.contains("G"))
		#expect(!stroke.startLetters.contains("P"))  // far corner
	}

	@Test func resamplePreservesEndpointsAndCount() {
		let source = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0), CGPoint(x: 10, y: 10)]
		let resampled = GlideStroke.resample(source, count: 32)
		#expect(resampled.count == 32)
		#expect(resampled.first == source.first)
		#expect(resampled.last == source.last)
	}
}
