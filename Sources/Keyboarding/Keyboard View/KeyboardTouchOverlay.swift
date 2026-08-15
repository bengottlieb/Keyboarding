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
#if canImport(AudioToolbox)
	import AudioToolbox
#endif

@Observable @MainActor final class KeyboardTouchModel {
	/// A finger's accumulated glide path: every sample point, plus the letter keys
	/// traversed with consecutive repeats collapsed. `isGliding` once it has
	/// crossed into a second letter — from then on the touch is a glide (trail,
	/// no bubble) and won't commit a key on release.
	struct GlideCapture {
		var points: [CGPoint] = []
		var letters: [String] = []
		var isGliding: Bool { letters.count > 1 }
	}

	// One entry per finger currently down, keyed by the key it first touched;
	// the value is the key now under that finger.
	private(set) var targets: [String: KeyDefinition] = [:]
	// Glide paths for fingers that started on a letter key (only while a glide
	// handler is installed), keyed like `targets`.
	private(set) var glides: [String: GlideCapture] = [:]
	// Keys whose finger lifted before the preview could be drawn, held just long
	// enough to be seen. A press long enough to have rendered is not in here — it
	// goes the moment the finger does (see `end`).
	private(set) var lingering: [String: KeyDefinition] = [:]

	private var lingerTasks: [String: Task<Void, Never>] = [:]
	/// Matches the original keyboard's minimum pop time.
	private let lingerDuration = Duration.milliseconds(100)
	/// How long a touch must last before its preview is assumed to have reached
	/// the screen. Anything longer hides the moment the finger lifts.
	private static let renderedAfter: TimeInterval = 0.05

	/// A press held longer than this is deliberate, and is never autocorrected.
	static let deliberatePress: TimeInterval = 0.75
	/// Typing assist only applies inside a fast burst. Pause longer than this to
	/// think and the key you pressed is the key you meant — the guard that keeps
	/// assist from fighting a considered guess.
	static let burstInterval: TimeInterval = 0.3

	// Assist bookkeeping, deliberately unobserved: when each finger landed, how
	// often it retargeted, and when a key last committed. Nothing renders from
	// these, and making them observable would redraw the overlay mid-touch.
	@ObservationIgnored private var downTimes: [String: Date] = [:]
	@ObservationIgnored private var retargets: [String: Int] = [:]
	@ObservationIgnored private var lastCommit: Date?

	// Live touches win over lingering ones for the same origin key.
	var visible: [String: KeyDefinition] { lingering.merging(targets) { _, live in live } }

	func update(origin: KeyDefinition, target: KeyDefinition?, click: Bool, haptic: Bool, now: Date = .now) {
		guard targets[origin.id] != target else { return }
		if let target {
			if targets[origin.id] == nil {
				// Click only when the finger lands (not on slide-retarget), and straight
				// from the gesture callback — waiting for a render would read as lag.
				if click { Self.playClick() }
				downTimes[origin.id] = now
				retargets[origin.id] = 0
			} else {
				// Sliding to a different key means the user is aiming: assist off.
				retargets[origin.id, default: 0] += 1
			}
			// Same reasoning as the click: from the callback, not from a render.
			if haptic { Self.playHaptic() }
			targets[origin.id] = target
		} else {
			// Slid off the keyboard: a deliberate cancel, no linger.
			targets.removeValue(forKey: origin.id)
		}
	}

	/// Whether this finger's press may be autocorrected, using the rules the
	/// original Crosswords keyboard used: it landed during a fast typing burst,
	/// wasn't held, and never slid to another key.
	func allowsAssist(origin: KeyDefinition, now: Date = .now) -> Bool {
		guard let lastCommit, now.timeIntervalSince(lastCommit) < Self.burstInterval,
		      let down = downTimes[origin.id], now.timeIntervalSince(down) < Self.deliberatePress,
		      retargets[origin.id, default: 0] == 0 else { return false }
		return true
	}

	/// Close out a committed press: starts the burst clock the next press is
	/// measured against.
	func recordCommit(origin: KeyDefinition, now: Date = .now) {
		lastCommit = now
		downTimes.removeValue(forKey: origin.id)
		retargets.removeValue(forKey: origin.id)
	}

	// The system keyboard "Tock", same sound at the same moment as a hardware keycap.
	private static func playClick() {
		#if canImport(AudioToolbox)
			AudioServicesPlaySystemSound(1104)
		#endif
	}

	#if os(iOS)
		// Kept alive and primed so the taptic engine is warm when a finger lands;
		// creating one per touch adds latency to the very cue it is meant to give.
		private static let haptics = UISelectionFeedbackGenerator()
	#endif

	/// Fired straight from the gesture callback, like the click — never from a
	/// view update. Routing it through `.sensoryFeedback` meant the thump waited
	/// on a SwiftUI render, and a late haptic reads worse than none at all: it is
	/// the strongest "the key registered" cue there is.
	private static func playHaptic() {
		#if os(iOS)
			haptics.selectionChanged()
			haptics.prepare()
		#endif
	}

	/// Record a glide sample: the raw point always, the key's letter when the
	/// finger is over a fresh letter key. Called only while glide is enabled and
	/// the touch began on a letter key.
	func glideSample(origin: KeyDefinition, point: CGPoint, over key: KeyDefinition?) {
		var capture = glides[origin.id] ?? GlideCapture()
		capture.points.append(point)
		if let letter = key?.string?.uppercased(), key?.type == .letter, capture.letters.last != letter {
			capture.letters.append(letter)
		}
		glides[origin.id] = capture
	}

	/// Close out a touch's glide path. The caller commits a tap only when the
	/// returned capture never became a glide.
	func endGlide(origin: KeyDefinition) -> GlideCapture? {
		glides.removeValue(forKey: origin.id)
	}

	func end(origin: KeyDefinition, now: Date = .now) {
		guard let key = targets.removeValue(forKey: origin.id) else { return }
		// A touch this long has certainly had a frame to draw the preview, so
		// releasing hides it at once — the way the original keyboard did. Lingering
		// unconditionally meant the bubble was still showing the previous key while
		// the next one went down, which is what reads as the preview lagging behind
		// the finger. Only a tap too brief to have rendered lingers, and then only
		// long enough to be seen at all.
		let held = downTimes[origin.id].map { now.timeIntervalSince($0) } ?? .greatestFiniteMagnitude
		guard held < Self.renderedAfter else { return }
		lingering[origin.id] = key
		lingerTasks[origin.id]?.cancel()
		lingerTasks[origin.id] = Task { [weak self, lingerDuration] in
			try? await Task.sleep(for: lingerDuration)
			guard !Task.isCancelled else { return }
			self?.lingering.removeValue(forKey: origin.id)
			self?.lingerTasks.removeValue(forKey: origin.id)
		}
	}
}

struct KeyboardTouchOverlay: View {
	let touches: KeyboardTouchModel
	let metrics: KeyboardMetrics
	@Environment(\.keyboardStyle) var kbStyle

	var body: some View {
		let visible = touches.visible
		ZStack(alignment: .topLeading) {
			// A touch that has become a glide shows the trail instead of the
			// bubble/tint — mid-glide there is no single "current key" to preview.
			ForEach(visible.keys.sorted(), id: \.self) { originID in
				// A spacer isn't a key: sliding over one shows nothing.
				if touches.glides[originID]?.isGliding != true,
				   let target = visible[originID], target.type != .blank, let rect = metrics.rect(for: target) {
					if target.type == .letter, let text = target.string {
						preview(text, over: rect)
					} else {
						// Delete, dismiss and friends get no popup — the tint is their
						// only feedback, so it has to stay.
						pressTint(over: rect)
					}
				}
			}
			ForEach(touches.glides.keys.sorted(), id: \.self) { originID in
				if let capture = touches.glides[originID], capture.isGliding {
					GlideTrailView(points: capture.points, metrics: metrics)
				}
			}
		}
		.allowsHitTesting(false)
	}

	// Matches the keycap face (which is inset 2pt within its frame).
	private func pressTint(over rect: CGRect) -> some View {
		RoundedRectangle(cornerRadius: kbStyle.cornerRadius)
			.fill(kbStyle.keyInk.opacity(0.12))
			.frame(width: rect.width - 4, height: rect.height - 4)
			.position(x: rect.midX, y: rect.midY)
	}

	@ViewBuilder
	private func preview(_ text: String, over rect: CGRect) -> some View {
		switch kbStyle.keyPreview {
		case .stemmed:
			// The stem is opaque and covers the keycap, so the key lifts rather than
			// sitting there tinted under a floating box — no separate tint wanted.
			stemmedPreview(text, over: rect)
		case .floating:
			pressTint(over: rect)
			floatingPreview(text, above: rect)
		}
	}

	/// Balloon AND the key it sits on as one shape, so the stem meets the keycap
	/// with no seam and hides it.
	private func stemmedPreview(_ text: String, over rect: CGRect) -> some View {
		let width = min(metrics.keyCapWidth * 1.6, metrics.bounds.width)
		let balloonHeight = metrics.keyCapHeight * 1.15
		// The stem stands in for the keycap's face, which KeyCapView insets by this
		// much inside the key's frame — match it, or the stem reads as a fatter key
		// than the ones around it.
		let capInset: CGFloat = 2
		let stem = CGSize(width: rect.width - capInset * 2, height: rect.height - capInset)
		let frame = CGRect(x: clampedX(over: rect, width: width),
		                   y: rect.maxY - capInset - balloonHeight - stem.height,
		                   width: width, height: balloonHeight + stem.height)
		// An edge key's balloon slides inward to stay on screen, so the stem is
		// placed from the key's real position rather than assumed centered.
		return KeyPreviewBubble(text: text, keyWidth: stem.width, keyHeight: stem.height,
		                        stemCenterX: rect.midX - frame.minX, balloonHeight: balloonHeight)
			.font(kbStyle.keyFont.font(size: metrics.keyCapWidth * 0.66))
			.frame(width: frame.width, height: frame.height)
			.position(x: frame.midX, y: frame.midY)
	}

	/// Detached rounded rectangle sitting above the key, which keeps its cap.
	private func floatingPreview(_ text: String, above rect: CGRect) -> some View {
		let width = min(metrics.keyCapWidth * 1.6, metrics.bounds.width)
		let height = metrics.keyCapHeight * 1.15
		let minX = clampedX(over: rect, width: width)
		// Balloon height for both the frame and the text box: with no stem the
		// letter centers in the whole popup.
		return KeyPreviewBubble(text: text, keyWidth: rect.width, keyHeight: 0,
		                        stemCenterX: rect.midX - minX, balloonHeight: height)
			.font(kbStyle.keyFont.font(size: metrics.keyCapWidth * 0.66))
			.frame(width: width, height: height)
			.position(x: minX + width / 2, y: rect.minY - height / 2 - 4)
	}

	/// Keeps a popup inside the keyboard's bounds; the key it points at may sit
	/// anywhere within it.
	private func clampedX(over rect: CGRect, width: CGFloat) -> CGFloat {
		min(max(rect.midX - width / 2, metrics.bounds.minX), metrics.bounds.maxX - width)
	}
}
