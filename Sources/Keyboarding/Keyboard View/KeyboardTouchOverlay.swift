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
	// Keys whose finger just lifted, kept visible briefly: a fast tap is shorter
	// than the bubble's render latency, so without this the preview never shows.
	private(set) var lingering: [String: KeyDefinition] = [:]
	private(set) var hapticPulse = 0

	private var lingerTasks: [String: Task<Void, Never>] = [:]
	private let lingerDuration = Duration.milliseconds(120)

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

	func update(origin: KeyDefinition, target: KeyDefinition?, click: Bool, now: Date = .now) {
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
			targets[origin.id] = target
			hapticPulse += 1
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

	func end(origin: KeyDefinition) {
		guard let key = targets.removeValue(forKey: origin.id) else { return }
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
					pressTint(over: rect)
					if target.type == .letter, let text = target.string {
						bubble(text, above: rect)
					}
				}
			}
			ForEach(touches.glides.keys.sorted(), id: \.self) { originID in
				if let capture = touches.glides[originID], capture.isGliding {
					GlideTrailView(points: capture.points, metrics: metrics)
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
