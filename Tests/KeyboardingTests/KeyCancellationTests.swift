import Foundation
import Testing
@testable import Keyboarding

@MainActor struct KeyCancellationTests {
	@Test func cancelledPRemovesFeedbackWithoutARelease() {
		let model = KeyboardTouchModel()
		let token = UUID()
		model.update(origin: "P", target: "P", click: false, haptic: false, touchID: token)
		#expect(model.visible[KeyDefinition("P").id] == KeyDefinition("P"))
		model.cancelIfActive(origin: "P", touchID: token)
		#expect(model.visible.isEmpty)
		#expect(!model.isActive(origin: "P"))
	}

	@Test func cancellationIsPerFingerAndOldResetCannotCancelNewP() {
		let model = KeyboardTouchModel()
		let old = UUID(), current = UUID(), other = UUID()
		model.update(origin: "P", target: "O", click: false, haptic: false, touchID: old)
		model.update(origin: "A", target: "S", click: false, haptic: false, touchID: other)
		model.cancelIfActive(origin: "P", touchID: old)
		#expect(model.visible.values.map(\.string) == ["S"])
		model.update(origin: "P", target: "P", click: false, haptic: false, touchID: current)
		model.cancelIfActive(origin: "P", touchID: old)
		#expect(model.isActive(origin: "P"))
		#expect(model.visible.count == 2)
	}

	@Test func normalBriefTapRetainsOnlyItsShortPreview() async throws {
		let model = KeyboardTouchModel()
		let token = UUID(), down = Date()
		model.update(origin: "P", target: "P", click: false, haptic: false, now: down, touchID: token)
		model.end(origin: "P", now: down.addingTimeInterval(0.01))
		model.cancelIfActive(origin: "P", touchID: token)
		#expect(!model.visible.isEmpty)
		try await Task.sleep(for: .milliseconds(180))
		#expect(model.visible.isEmpty)
	}

	@Test func cancellationDropsGlideAndPendingHold() async throws {
		let model = KeyboardTouchModel()
		let token = UUID()
		var fired = false
		model.update(origin: "P", target: "P", click: false, haptic: false, touchID: token)
		model.armLongPress(origin: "P") { _ in fired = true; return true }
		model.glideSample(origin: "P", point: .zero, over: "P")
		model.cancelIfActive(origin: "P", touchID: token)
		try await Task.sleep(for: KeyboardTouchModel.longPressDuration + .milliseconds(120))
		#expect(!fired)
		#expect(model.glides.isEmpty)
		#expect(model.visible.isEmpty)
		#expect(!model.consumedLongPress(origin: "P"))
	}

	@Test func disappearingKeyboardClearsEveryFingerAndLinger() async throws {
		let model = KeyboardTouchModel()
		let now = Date()
		model.update(origin: "P", target: "P", click: false, haptic: false, now: now)
		model.end(origin: "P", now: now.addingTimeInterval(0.01))
		model.update(origin: "A", target: "A", click: false, haptic: false)
		model.cancelAll()
		#expect(model.visible.isEmpty)
		#expect(!model.isActive(origin: "A"))
		try await Task.sleep(for: .milliseconds(180))
		#expect(model.visible.isEmpty)
	}
}
