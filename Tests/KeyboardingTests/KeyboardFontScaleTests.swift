//
//  KeyboardFontScaleTests.swift
//  KeyboardingTests
//
//  A host's scale sizes typed characters over the keyboard's own size for
//  them, but never grows one past the box it is drawn in.
//

import Testing
import CoreGraphics
@testable import Keyboarding

@MainActor
@Suite("A key font's scale")
struct KeyboardFontScaleTests {
	private let roomy = CGSize(width: 100, height: 100)

	@Test("at 1 a glyph is the keyboard's own size, wherever it is drawn")
	func unscaledIsUnchanged() {
		let font = KeyboardFont()
		#expect(font.scale == 1)
		#expect(font.size(base: 18, fitting: roomy) == 18)
		// Even a box the default already overfills (a landscape phone's balloon).
		#expect(font.size(base: 48, fitting: CGSize(width: 117, height: 50)) == 48)
	}

	@Test("a larger scale grows a glyph that has room")
	func largerScaleGrows() {
		let font = KeyboardFont(scale: 1.3)
		#expect(abs(font.size(base: 18, fitting: roomy) - 23.4) < 0.001)
	}

	@Test("a larger scale stops at what the box holds, never below the keyboard's own size")
	func largerScaleIsHeldToTheBox() {
		let font = KeyboardFont(scale: 1.3)
		let box = CGSize(width: 24, height: 100)
		#expect(font.size(base: 18, fitting: box) == KeyboardFont.largestFitting(box))
		#expect(font.size(base: 48, fitting: CGSize(width: 117, height: 50)) == 48)
	}

	@Test("a smaller scale always applies")
	func smallerScaleShrinks() {
		let font = KeyboardFont(scale: 0.8)
		#expect(abs(font.size(base: 48, fitting: CGSize(width: 10, height: 10)) - 38.4) < 0.001)
	}

	@Test("at 130% a letter fits its cap and its preview on a small phone")
	func smallPhoneFits() {
		// iPhone SE / 16e class, portrait: the narrowest letter keys a phone has.
		let metrics = KeyboardMetrics(keymap: .qwerty, width: 375, keyCapHeight: 54, horizontalMargin: 8)
		let font = KeyboardFont(scale: 1.3)
		let cap = font.size(base: metrics.glyphSize, fitting: metrics.faceSize)
		#expect(cap > metrics.glyphSize)
		#expect(cap <= KeyboardFont.largestFitting(metrics.faceSize))
		let balloon = CGSize(width: metrics.keyCapWidth * 1.6, height: metrics.keyCapHeight * 1.15)
		#expect(font.size(base: metrics.keyCapWidth * 0.66, fitting: balloon) <= KeyboardFont.largestFitting(balloon))
	}
}

@MainActor
@Suite("A key's letter at its default size")
struct KeyGlyphSizeTests {
	@Test("about 21–22pt on a 402pt phone in portrait, and it fits the face everywhere")
	func defaultSize() {
		let phone = KeyboardMetrics(keymap: .qwerty, width: 402, keyCapHeight: 54, horizontalMargin: 8)
		#expect((21...22).contains(phone.glyphSize))
		for metrics in [phone,
		                KeyboardMetrics(keymap: .qwerty, width: 375, keyCapHeight: 54, horizontalMargin: 8),
		                KeyboardMetrics(keymap: .qwerty, width: 750, keyCapHeight: 44, horizontalMargin: 8),
		                KeyboardMetrics(keymap: .qwerty, width: 1024, keyCapHeight: 54, horizontalMargin: 8)] {
			#expect(metrics.glyphSize <= KeyboardFont.largestFitting(metrics.faceSize))
		}
	}
}
